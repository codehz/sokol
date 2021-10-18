import std/[macros, options, strutils, tables]
import ./private/backend
import ./gfx
import ./common

when not defined(shdcExec):
  when defined(windows):
    const shdcExec* = "cmd /c ..\\tools\\sokol-shdc.exe"
  else:
    const shdcExec* = "../tools/sokol-shdc"

when sokol_backend == "D3D11":
  const slang {.strdefine.} = "hlsl5"
  func acceptKind(name: string): bool = name == "hlsl5" or name == "hlsl4"
elif sokol_backend == "GLCORE33":
  const slang {.strdefine.} = "glsl330"
  func acceptKind(name: string): bool = name == "glsl330"
elif sokol_backend == "GLES2":
  const slang {.strdefine.} = "glsl100"
  func acceptKind(name: string): bool = name == "glsl100"
elif sokol_backend == "GLES3":
  const slang {.strdefine.} = "glsl300es"
  func acceptKind(name: string): bool = name == "glsl300es"
elif sokol_backend == "METAL":
  when defined (macosx):
    const slang {.strdefine.} = "metal_macos"
    func acceptKind(name: string): bool = name == "metal_macos"
  else:
    const slang {.strdefine.} = "metal_ios"
    func acceptKind(name: string): bool = name == "metal_ios"
elif sokol_backend == "WGPU":
  const slang {.strdefine.} = "wgpu"
  func acceptKind(name: string): bool = name == "wgpu"
else:
  {.error: "Cannot detect shader language".}

func packed(node: NimNode): NimNode =
  nnkPragmaExpr.newTree(node, nnkPragma.newTree(ident "packed"))

func align16(node: NimNode): NimNode =
  nnkPragmaExpr.newTree(node, nnkPragma.newTree(newCall("align", newLit 16)))

func arrayty(count: Natural, node: NimNode): NimNode =
  if count == 1: return node
  nnkBracketExpr.newTree(bindSym "array", newLit count, node)

func decodeShaderAttributeDesc(node: NimNode): NimNode =
  result = nnkObjConstr.newTree(bindSym "ShaderAttributeDesc")
  when sokol_backend == "D3D11":
    result.add nnkExprColonExpr.newTree(ident "sem_name", newLit node[3].strVal)
    result.add nnkExprColonExpr.newTree(ident "sem_index", newLit int32 node[4].intVal)
  else:
    result.add nnkExprColonExpr.newTree(ident "name", newLit node[1].strVal)

func decodeShaderAttributes(node: NimNode): NimNode =
  result = newNimNode nnkBracket
  for item in node:
    if item.kind == nnkCommand and item[0].strVal == "attribute":
      let idx = int item[2].intVal
      while idx >= result.len:
        result.add nnkObjConstr.newTree(bindSym "ShaderAttributeDesc")
      result[idx] = decodeShaderAttributeDesc(item)

type ShaderSource = object
  sym: NimNode
  kind: string
  binary: bool

func decodeShaderStageDesc(node: NimNode, src: ShaderSource, structs: var Table[string, int]): NimNode =
  let stmt = newStmtList()
  let s = nskVar.genSym "tmp"
  let base = nnkObjConstr.newTree(bindSym "ShaderStageDesc")
  stmt.add nnkVarSection.newTree(
    newIdentDefs(s, newEmptyNode(), base)
  )
  base.add newColonExpr(ident "entry", newLit node[2].strVal)
  if src.binary:
    base.add newColonExpr(ident "bytecode", src.sym)
  else:
    base.add newColonExpr(ident "source", src.sym)
  when sokol_backend == "D3D11":
    let prefix = if node[0].strVal == "vertex": "vs_" else: "ps_"
    let ver = if src.kind == "hlsl5": "5_0" else: "4_0"
    base.add newColonExpr(ident "d3d11_target", newLit prefix & ver)
  for item in node[3]:
    if item.kind == nnkCommand:
      case item[0].strVal:
      of "uniform":
        let name = item[1].strVal
        let idx = item[2].intVal
        let size = structs[name]
        stmt.add quote do:
          `s`.uniform_blocks[`idx`].size = `size`
        when sokol_backend.startsWith "GL":
          let namelit = newLit name
          let xsize = uint32(size div 16)
          stmt.add quote do:
            `s`.uniform_blocks[`idx`].uniforms[0].name = `namelit`
            `s`.uniform_blocks[`idx`].uniforms[0].kind = u_float4
            `s`.uniform_blocks[`idx`].uniforms[0].count = `xsize`
      of "image":
        let name = item[1].strVal
        let idx = item[2].intVal
        let image_kind = nnkCast.newTree(bindSym "ImageKind", newLit int32 item[3].intVal)
        let sampler_kind = nnkCast.newTree(bindSym "SamplerKind", newLit int32 item[4].intVal)
        stmt.add quote do:
          `s`.images[`idx`].name = `name`
          `s`.images[`idx`].image_kind = `image_kind`
          `s`.images[`idx`].sampler_kind = `sampler_kind`
  stmt.add s
  newBlockStmt(stmt)

macro loadshader*(contents: static string) =
  result = newStmtList()
  let varsec = newNimNode nnkVarSection
  let typesec = newNimNode nnkTypeSection
  let staticsec = newStmtList()
  let programsec = newNimNode nnkLetSection
  var programs: seq[NimNode]
  var sources: Table[string, ShaderSource] 
  var structs: Table[string, int]
  result.add varsec
  result.add typesec
  result.add nnkStaticStmt.newTree(staticsec)
  result.add programsec
  let stmts = parseStmt(contents)
  for stmt in stmts:
    assert stmt.kind == nnkCommand
    let command = stmt[0].strVal
    case command:
    of "metadata":
      assert stmt[1].intVal == 1
    of "version":
      discard
    of "struct":
      let name = stmt[1]
      let size = stmt[2].intVal
      let body = stmt[3]
      let objfields = nnkRecList.newNimNode()
      let obj = nnkObjectTy.newTree(newEmptyNode(), newEmptyNode(), objfields)
      for field in body:
        assert field.kind == nnkCommand
        if field[0].strVal == "field":
          let fn = field[1]
          let ft = field[2]
          let fc = field[3].intVal
          objfields.add nnkIdentDefs.newTree(
            fn.align16,
            arrayty(fc, ft),
            newEmptyNode()
          )
      let struct = nnkTypeDef.newTree(
        name.packed,
        newEmptyNode(),
        obj
      )
      typesec.add struct
      staticsec.add quote do:
        assert sizeof(`name`) == `size`, "struct size mismatched, please check custom type"
      structs[name.strVal] = int size
    of "program":
      programs.add stmt
    of "source", "bytecode":
      let name = stmt[1].strVal
      let kind = stmt[2].strVal
      let body = stmt[3]
      if acceptKind(kind):
        let sym = nskVar.genSym name
        sources[name] = ShaderSource(sym: sym, binary: command == "bytecode", kind: kind)
        var code: string
        for line in body:
          assert line[0].strVal == "put"
          code.add parseHexStr line[1].strVal
        varsec.add newIdentDefs(sym, newEmptyNode(), newLit code)
    else:
      echo command
  for program in programs:
    let name = program[1]
    let body = program[2]
    let vs = body[0]
    let vssrc = sources[vs[1].strVal]
    let fs = body[1]
    let fssrc = sources[fs[1].strVal]

    let definestr = newCall(bindSym "defineShaderDesc")
    definestr.add newLit name.strVal
    definestr.add decodeShaderAttributes(vs[3])
    definestr.add decodeShaderStageDesc(vs, vssrc, structs)
    definestr.add decodeShaderStageDesc(fs, fssrc, structs)
    programsec.add newIdentDefs(
      name,
      newEmptyNode(),
      definestr
    )

macro compileshader*(content: static string) =
  let (output, code) = gorgeEx(shdcExec & " -i @ -l " & slang & " -o @ -f nim -b", content, "OwO")
  doAssert code == 0, "Failed to compile shader: " & output
  quote do:
    loadshader `output`

template importshader*(filename: static string) =
  compileshader(staticRead(filename))