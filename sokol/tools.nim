{.experimental: "caseStmtMacros".}

import std/[macros, options, strutils, tables, os, genasts, sugar]
import ./private/[backend, astpat]
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
    case item:
    of (uniform(`name`, `idx`)):
      let size = structs[name.strVal]
      stmt.add quote do:
        `s`.uniform_blocks[`idx`].size = `size`
      when sokol_backend.startsWith "GL":
        let namelit = newLit name.strVal
        let xsize   = uint32(size div 16)
        stmt.add quote do:
          `s`.uniform_blocks[`idx`].uniforms[0].name  = `namelit`
          `s`.uniform_blocks[`idx`].uniforms[0].kind  = u_float4
          `s`.uniform_blocks[`idx`].uniforms[0].count = `xsize`
    of (image(`id_name`, `idx`, `raw_image_kind`, `raw_sampler_kind`)):
      let name = newLit id_name.strVal
      let image_kind   = nnkCast.newTree(bindSym "ImageKind", newLit int32 raw_image_kind.intVal)
      let sampler_kind = nnkCast.newTree(bindSym "SamplerKind", newLit int32 raw_sampler_kind.intVal)
      stmt.add quote do:
        `s`.images[`idx`].name         = `name`
        `s`.images[`idx`].image_kind   = `image_kind`
        `s`.images[`idx`].sampler_kind = `sampler_kind`
  stmt.add s
  newBlockStmt(stmt)

func attachattrs(name, vs, fs: NimNode): NimNode =
  let attrs = newNimNode nnkTableConstr
  let outputs = newNimNode nnkTableConstr
  let vsdefs = newNimNode nnkTableConstr
  let fsdefs = newNimNode nnkTableConstr
  for item in vs:
    case item:
    of (attribute(`name`, `idx`, `sem_name`, `sem_index`)):
      discard (sem_name, sem_index)
      attrs.add newColonExpr(name, idx)
    of (uniform(`name`, `idx`)):
      vsdefs.add newColonExpr(idx, newCall(ident "struct", name))
    of (image(`name`, `idx`, `_`, `_`)):
      vsdefs.add newColonExpr(idx, newCall(ident "image", name))
  for item in fs:
    case item:
    of (output(`name`, `idx`)):
      outputs.add newColonExpr(name, idx)
    of (uniform(`name`, `idx`)):
      fsdefs.add newColonExpr(idx, newCall(ident "struct", name))
    of (image(`name`, `idx`, `_`, `_`)):
      fsdefs.add newColonExpr(idx, newCall(ident "image", name))
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
    case stmt:
    of (metadata `val`):
      assert val.intVal == 1
    of (version `ver`):
      discard ver
    of (struct(`name`, `size`, `body*`)):
      let objfields = nnkRecList.newNimNode()
      let obj = nnkObjectTy.newTree(newEmptyNode(), newEmptyNode(), objfields)
      for field in body:
        case field:
        of (field(`fn`, `ft`, `fc`)):
          objfields.add nnkIdentDefs.newTree(
            fn,
            arrayty(fc.intVal, ft),
            newEmptyNode()
          )
        of (padding(`off`, `len`)):
          let padding = nskField.genSym "padding" & $off.intVal
          objfields.add nnkIdentDefs.newTree(
            padding,
            arrayty(len.intVal, bindSym "byte"),
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
      structs[name.strVal] = int size.intVal
    of (program(`name`, `body*`)):
      discard (name, body)
      programs.add stmt
    of (source(`name`, `kind`, `body*`)), (bytecode(`name`, `kind`, `body*`)):
      if acceptKind(kind.strVal):
        let sym = nskVar.genSym name.strVal
        sources[name.strVal] = ShaderSource(sym: sym, binary: stmt[0].strVal == "bytecode", kind: kind.strVal)
        var code: string
        for line in body:
          assert line[0].strVal == "put"
          code.add parseHexStr line[1].strVal
        varsec.add newIdentDefs(sym, newEmptyNode(), newLit code)
    else:
      warning("invalid command: " & stmt[0].strVal)
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
    case pragma:
    of (uniforms: `uniforms*`):
      for kv in uniforms:
        case kv:
        of (`keyid`: `mapping*`):
          let key = keyid.strVal
          if (key == "fs" and stage == stage_fs) or (key == "vs" and stage == stage_vs):
            for it in mapping:
              case it:
              of (`idx`: struct(`name`)):
                if value.getTypeInst().strVal == name.strVal:
                  return genAst(idx = uint32 idx.intVal, stage, value):
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
  case node:
  of (float32): return vf_float
  of (array[1, float32]): return vf_float
  of (array[2, float32]): return vf_float2
  of (array[3, float32]): return vf_float3
  of (array[4, float32]): return vf_float4
  of (array[4, int8]): return if normal: vf_byte4n else: vf_byte4
  of (array[4, uint8]): return if normal: vf_ubyte4n else: vf_ubyte4
  of (array[2, int16]): return if normal: vf_short2n else: vf_short2
  of (array[4, int16]): return if normal: vf_short4n else: vf_short4
  of (array[2, uint16]): return vf_ushort2n
  of (array[4, uint16]): return vf_ushort4n
  of (array[2, uint16]): return vf_uint10_n2
  else: return vf_invalid

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

func fix(expr: NimNode, replacements: Table[string, NimNode]): NimNode =
  if expr.kind == nnkIdent:
    copy replacements[expr.strVal]
  else:
    expr[0] = fix(expr[0], replacements)
    expr

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
  let cpipeline = nnkObjConstr.newTree(bindSym "PipelineDesc")
  let tpipeline = nskVar.genSym "pipeline_desc"
  result.add newVarStmt(tpipeline, cpipeline)
  for kv in st:
    case kv:
    of (outputs: `list*`):
      for col in list:
        outputs[col[0].strVal] = int col[1].intVal
    of (uniforms: `list*`):
      for typ in list:
        case typ:
        of (fs: `tab*`):
          for col in tab:
            if col[1][0].strVal != "image": continue
            fs[col[1][1].strVal] = int col[0].intVal
        of (vs: `tab*`):
          for col in tab:
            if col[1][0].strVal != "image": continue
            vs[col[1][1].strVal] = int col[0].intVal
  for item in body:
    case item:
    of (vertex_buffers = `list*`), (bindings.vertex_buffers = `list*`):
      for i, item in list.pairs:
        let vitem = dict.popped(item.strVal)
        vertex_buffers.add vitem
        let label = newLit(shader.strVal & "-" & item.strVal)
        result.add quote do:
          `tmp`.bindings.vertex_buffers[`i`] = make BufferDesc(data: `vitem`, label: `label`)
    of (index_buffer = `list`), (bindings.index_buffer = `list`):
      index_buffer = dict.popped(list.strVal)
      let label = newLit(shader.strVal & "-indices")
      result.add quote do:
        `tmp`.bindings.index_buffer = make BufferDesc(data: `index_buffer`, kind: bk_index, label: `label`)
    of (fs_images[`texid`] = `imgdesc`), (bindings.fs_images[`texid`] = `imgdesc`):
      let imgidx = fs.popped(texid.strVal)
      let val = dict.popped(imgdesc.strVal)
      var timg: NimNode
      if val.getTypeInst.sameType getType(Image):
        timg = val
      elif val.getTypeInst.sameType getType(ImageDesc):
        timg = newCall(bindSym "make", val)
      result.add quote do:
        `tmp`.bindings.fs_images[`imgidx`] = `timg`
    of (vs_images[`texid`] = `imgdesc`), (bindings.vs_images[`texid`] = `imgdesc`):
      let imgidx = vs.popped(texid.strVal)
      let val = dict.popped(imgdesc.strVal)
      var timg: NimNode
      if val.getTypeInst.sameType getType(Image):
        timg = val
      elif val.getTypeInst.sameType getType(ImageDesc):
        timg = newCall(bindSym "make", val)
      result.add quote do:
        `tmp`.bindings.vs_images[`imgidx`] = `timg`
    of (action.colors[`oid`] = `value*`):
      let colidx = outputs[oid.strVal]
      result.add quote do:
        `tmp`.action.colors[`colidx`] = `value`
    of (pipeline.colors[`oid`] = `value*`):
      let colidx = outputs[oid.strVal]
      result.add quote do:
        `tpipeline`.colors[`colidx`] = `value`
    of (`_*` = `_*`):
      result.add: fix(item): toTable {
        "pipeline": tpipeline,
        "action": newDotExpr(tmp, ident "action"),
        "bindings": newDotExpr(tmp, ident "bindings")
      }
    else:
      error("invalid stmt: " & repr item)
  let cshader = newCall(bindSym "make", shader)
  let clayout = newCall(bindSym "layout", shader)
  for buf in vertex_buffers: clayout.add buf.getType()[2]
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
    `tmp`.pipeline = make(`tpipeline`)
  result.add tmp
  # echo treerepr result
  return
