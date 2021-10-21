import std/[macros, options, strutils, tables, os, genasts, sugar]
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

template attributes(tab: untyped) {.pragma.}
template outputs(tab: untyped) {.pragma.}
template uniforms(tab: untyped) {.pragma.}

template instance*() {.pragma.}
template step*(value: typed) {.pragma.}

template normalized*() {.pragma.}
template underlying*(t: typed) {.pragma.}
type uint10* = distinct uint16

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

func attachattrs(name, vs, fs: NimNode): NimNode =
  let attrs = newNimNode nnkTableConstr
  let outputs = newNimNode nnkTableConstr
  let vsdefs = newNimNode nnkTableConstr
  let fsdefs = newNimNode nnkTableConstr
  for item in vs:
    if item.kind != nnkCommand: continue
    case item[0].strVal:
    of "attribute":
      let name = ident item[1].strVal
      let idx = item[2].intVal
      attrs.add newColonExpr(name, newLit idx)
    of "uniform":
      vsdefs.add newColonExpr(item[2], newCall(ident "struct", item[1]))
    of "image":
      vsdefs.add newColonExpr(item[2], newCall(ident "image", item[1]))
  for item in fs:
    if item.kind != nnkCommand: continue
    case item[0].strVal:
    of "uniform":
      fsdefs.add newColonExpr(item[2], newCall(ident "struct", item[1]))
    of "image":
      fsdefs.add newColonExpr(item[2], newCall(ident "image", item[1]))
    of "output":
      let name = ident item[1].strVal
      let idx = item[2].intVal
      outputs.add newColonExpr(name, newLit idx)
  result = nnkPragmaExpr.newTree(
    name,
    nnkPragma.newTree(
      newColonExpr(bindSym "attributes", attrs),
      newColonExpr(bindSym "outputs", outputs)
    )
  )
  let uniformsdef = newNimNode nnkTableConstr
  if vsdefs.len > 0: uniformsdef.add newColonExpr(ident "vs", vsdefs)
  if fsdefs.len > 0: uniformsdef.add newColonExpr(ident "fs", fsdefs)
  if uniformsdef.len > 0: result[1].add newColonExpr(bindSym "uniforms", uniformsdef)

macro loadshader*(contents: static string) =
  result = newStmtList()
  let varsec = newNimNode nnkVarSection
  let typesec = newStmtList()
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
      let typedef = nnkTypeSection.newTree(struct)
      typesec.add quote do:
        when not declared(`name`):
          `typedef`
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
      name.attachattrs(vs[3], fs[3]),
      newEmptyNode(),
      definestr
    )

macro `[]=`*(desc: ShaderDesc, stage: static ShaderStage, value: typed{`let`|`var`}) =
  let maypragma = getImpl(desc)[0]
  maypragma.expectKind nnkPragmaExpr
  let pragmas = maypragma[1]
  for pragma in pragmas:
    if pragma.kind in { nnkCommand, nnkExprColonExpr } and pragma[0].strVal == "uniforms":
      let uniforms = pragma[1]
      for kv in uniforms:
        kv.expectKind nnkExprColonExpr
        let key = kv[0].strVal
        let mapping = kv[1]
        if (key == "fs" and stage == stage_fs) or (key == "vs" and stage == stage_vs):
          for it in mapping:
            if it[1][0].strVal == "struct":
              if value.getTypeInst().strVal == it[1][1].strVal:
                return genAst(idx = uint32 it[0].intVal, stage, value):
                  apply_uniforms(stage, idx, value)
          error("target uniform not found")
      error("the shader stage don't have any uniforms")
  error("invalid shader desc")

macro compileshader*(content: static string) =
  let (output, code) = gorgeEx(shdcExec & " -i @ -l " & slang & " -o @ -f nim -b", content, "OwO")
  doAssert code == 0, "Failed to compile shader: " & output & " code: " & $code
  genAst(output): loadshader output

macro importshader*(filename: typed{nkStrLit}) =
  let path = filename.lineInfoObj.filename.joinPath("..", filename.strVal)
  let content = staticRead path
  genAst(content): compileshader content

func mapFormat(node: NimNode, normal: bool): VertexFormat =
  if node.kind == nnkSym:
    node.expectIdent "float32"
    return vf_float
  elif node.kind == nnkBracketExpr:
    node[0].expectIdent "array"
    let
      base = node[2]
      count = node[1].intVal
    base.expectKind nnkSym
    case base.strVal:
    of "float32":
      case count:
      of 1:
        return vf_float
      of 2:
        return vf_float2
      of 3:
        return vf_float3
      of 4:
        return vf_float4
      else:
        return vf_invalid
    of "int8":
      case count:
      of 4:
        return if normal: vf_byte4n else: vf_byte4
      else:
        return vf_invalid
    of "uint8":
      case count:
      of 4:
        return if normal: vf_ubyte4n else: vf_ubyte4
      else:
        return vf_invalid
    of "int16":
      case count:
      of 2:
        return if normal: vf_short2n else: vf_short2
      of 4:
        return if normal: vf_short4n else: vf_short4
      else:
        return vf_invalid
    of "uint16":
      case count:
      of 2:
        return vf_ushort2n
      of 4:
        return vf_ushort4n
      else:
        return vf_invalid
    of "uint10":
      case count:
      of 2:
        return vf_uint10_n2
      else:
        return vf_invalid

macro layout*(it: ShaderDesc, bufs: varargs[typed]): LayoutDesc =
  var attrsmap: Table[string, int]
  var buffers: seq[BufferLayoutDesc]
  var attrs: Table[int, tuple[buffer: int, offset: int, format: VertexFormat]]
  let defs = it.getImpl
  defs.expectKind nnkIdentDefs
  defs[0][1].expectKind nnkPragma
  for p in defs[0][1]:
    if (p.kind == nnkCall or p.kind == nnkExprColonExpr) and p[0].strVal == "attributes":
      p[1].expectKind nnkTableConstr
      attrsmap = collect:
        for kv in p[1]: { kv[0].strVal: int kv[1].intVal }
      break
  for bufid, typ in bufs.pairs:
    let
      impl = typ.getImpl
      deflist = impl[2][2]
      implname = impl[0]
      implsym = if implname.kind == nnkSym: implname else: implname[0]
      symlist = implsym.getType[2]
    if implname.kind == nnkPragmaExpr:
      let implpragma = implname[1]
      var tmp = BufferLayoutDesc(stride: uint32 typ.getSize)
      for p in implpragma:
        if p.kind in {nnkExprColonExpr, nnkCall} and p[0].strVal == "step":
          tmp.step_rate = uint32 p[1].intVal
        elif p.kind == nnkSym and p.strVal == "instance":
          tmp.step_func = vs_per_instance
      buffers.add tmp
    else:
      buffers.add BufferLayoutDesc(stride: uint32 typ.getSize)
    for i, sym in symlist.pairs:
      let
        def = deflist[i]
        aname = sym.strVal
        idx = attrsmap[aname]
      var
        deftype = def[1]
        normal = false
      if def[0].kind == nnkPragmaExpr:
        for p in def[0][1]:
          if p.kind == nnkSym and p.strVal == "normalized":
            normal = true
          if p.kind in {nnkExprColonExpr, nnkCall} and p[0].strVal == "underlying":
            assert deftype.getSize == p[1].getSize
            deftype = p[1]
      let format = mapFormat(deftype, normal)
      assert format != vf_invalid, "invalid type: " & repr deftype
      attrs[idx] = (buffer: bufid, offset: sym.getOffset, format: mapFormat(deftype, normal))
  let stmt = newNimNode nnkStmtList
  let retsym = nskVar.genSym "ret"
  stmt.add quote do:
    var `retsym`: LayoutDesc
  for i, info in buffers:
    let stride = newLit info.stride
    let step_func = newLit info.step_func
    let step_rate = newLit info.step_rate
    stmt.add quote do:
      `retsym`.buffers[`i`].stride = `stride`
      `retsym`.buffers[`i`].step_func = `step_func`
      `retsym`.buffers[`i`].step_rate = `step_rate`
  for i, (buffer, offset, format) in attrs:
    let fmtlit = newLit format
    stmt.add quote do:
      `retsym`.attrs[`i`].buffer_index = `buffer`
      `retsym`.attrs[`i`].offset = `offset`
      `retsym`.attrs[`i`].format = `fmtlit`
  stmt.add retsym
  newBlockStmt(stmt)

func popped[K, V](tab: var Table[K, V], key: K): V =
  doAssert tab.pop(key, result), $key & " not found or used already"

macro build*(shader: ShaderDesc{`let`}, dictsrc: varargs[typed]{`let`|`var`}, body: untyped{nkStmtList}): PassState =
  result = newStmtList()
  let tmp = nskVar.genSym "tmp"
  result.add quote do:
    var `tmp`: PassState
  var dict = collect:
    for kv in dictsrc: { kv.strVal: kv }
  var vertex_buffers: seq[NimNode]
  var index_buffer: NimNode
  var outputs: Table[string, int]
  var vs, fs: Table[string, int]
  let st: NimNode = shader.getImpl[0][1]
  for kv in st:
    kv.expectKind nnkExprColonExpr
    case kv[0].strVal:
    of "outputs":
      for col in kv[1]:
        outputs[col[0].strVal] = int col[1].intVal
    of "uniforms":
      for typ in kv[1]:
        case typ[0].strVal:
        of "fs":
          for col in typ[1]:
            if col[1][0].strVal != "image": continue
            fs[col[1][1].strVal] = int col[0].intVal
        of "vs":
          for col in typ[1]:
            if col[1][0].strVal != "image": continue
            vs[col[1][1].strVal] = int col[0].intVal
  for item in body:
    item.expectKind nnkAsgn
    case item[0].kind:
    of nnkIdent:
      case item[0].strVal:
      of "vertex_buffers":
        for i, item in item[1].pairs:
          let vitem = dict.popped(item.strVal)
          vertex_buffers.add vitem
          let label = newLit(shader.strVal & "-" & item.strVal)
          result.add quote do:
            `tmp`.bindings.vertex_buffers[`i`] = make BufferDesc(data: `vitem`, label: `label`)
      of "index_buffer":
        index_buffer = dict.popped(item[1].strVal)
        let label = newLit(shader.strVal & "-indices")
        result.add quote do:
          `tmp`.bindings.index_buffer = make BufferDesc(data: `index_buffer`, kind: bk_index, label: `label`)
      else:
        error("unknown params: " & item[0].strVal)
    of nnkBracketExpr:
      let bidx = item[0][1]
      case item[0][0].kind:
      of nnkIdent:
        case item[0][0].strVal:
        of "fs_images":
          let imgidx = fs.popped(bidx.strVal)
          let val = dict.popped(item[1].strVal)
          var timg: NimNode
          if val.getTypeInst.sameType getType(Image):
            timg = val
          elif val.getTypeInst.sameType getType(ImageDesc):
            timg = newCall(bindSym "make", val)
          result.add quote do:
            `tmp`.bindings.fs_images[`imgidx`] = `timg`
        of "vs_images":
          let imgidx = vs.popped(bidx.strVal)
          let val = dict.popped(item[1].strVal)
          var timg: NimNode
          if val.getTypeInst.sameType getType(Image):
            timg = val
          elif val.getTypeInst.sameType getType(ImageDesc):
            timg = newCall(bindSym "make", val)
          result.add quote do:
            `tmp`.bindings.vs_images[`imgidx`] = `timg`
        of "colors":
          let colidx = outputs.popped(bidx.strVal)
          let val = item[1]
          result.add quote do:
            `tmp`.action.colors[`colidx`] = `val`
        else:
          error("unknown attr " & item[0][0].strVal)
      else:
        error("invalid stmt: " & repr item[0])
    else:
      error("invalid stmt: " & repr item[0])
  let cshader = newCall(bindSym "make", shader)
  let clayout = newCall(bindSym "layout", shader)
  for buf in vertex_buffers: clayout.add buf.getType()[2]
  let cpipeline = nnkObjConstr.newTree(bindSym "PipelineDesc")
  cpipeline.add newColonExpr(ident "shader", cshader)
  cpipeline.add newColonExpr(ident "layout", clayout)
  if index_buffer.kind != nnkNilLit:
    let ibufty = index_buffer.getType
    ibufty.expectKind nnkBracketExpr
    ibufty[0].expectIdent "array"
    if ibufty[2].sameType getType(uint16):
      cpipeline.add newColonExpr(ident "index_kind", newLit idx_uint16)
    elif ibufty[2].sameType getType(uint32):
      cpipeline.add newColonExpr(ident "index_kind", newLit idx_uint32)
    else:
      error("invalid index type: " & $ibufty[2])
  cpipeline.add newColonExpr(ident "label", newLit(shader.strVal & "-pipeline"))
  result.add quote do:
    `tmp`.pipeline = make(`cpipeline`)
  result.add tmp
  # echo repr result
  return
