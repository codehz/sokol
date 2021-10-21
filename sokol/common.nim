import macros

type
  PixelFormat* {.pure, size: 4.} = enum
    pf_default
    pf_none,
    pf_r8,
    pf_r8sn,
    pf_r8ui,
    pf_r8si,
    pf_r16,
    pf_r16sn,
    pf_r16ui,
    pf_r16si,
    pf_r16f,
    pf_rg8,
    pf_rg8sn,
    pf_rg8ui,
    pf_rg8si,
    pf_r32ui,
    pf_r32si,
    pf_r32f,
    pf_rg16,
    pf_rg16sn,
    pf_rg16ui,
    pf_rg16si,
    pf_rg16f,
    pf_rgba8,
    pf_rgba8sn,
    pf_rgba8ui,
    pf_rgba8si,
    pf_bgra8,
    pf_rgb10a2,
    pf_rg11b10f,
    pf_rg32ui,
    pf_rg32si,
    pf_rg32f,
    pf_rgba16,
    pf_rgba16sn,
    pf_rgba16ui,
    pf_rgba16si,
    pf_rgba16f,
    pf_rgba32ui,
    pf_rgba32si,
    pf_rgba32f,
    pf_depth,
    pf_depth_stencil,
    pf_bc1_rgba,
    pf_bc2_rgba,
    pf_bc3_rgba,
    pf_bc4_r,
    pf_bc4_rsn,
    pf_bc5_rg,
    pf_bc5_rgsn,
    pf_bc6h_rgbf,
    pf_bc6h_rgbuf,
    pf_bc7_rgba,
    pf_pvrtc_rgb_2bpp,
    pf_pvrtc_rgb_4bpp,
    pf_pvrtc_rgba_2bpp,
    pf_pvrtc_rgba_4bpp,
    pf_etc2_rgb8,
    pf_etc2_rgb8a1,
    pf_etc2_rgba8,
    pf_etc2_rg11,
    pf_etc2_rg11sn,
  RangePtr* = object
    head*: pointer
    size*: int
  ConstView*[T] = distinct ptr T
  MaybeVar*[T] = T | var T

func rangePtrFromArray*[T](arr: openArray[T]): RangePtr =
  RangePtr(head: arr[0].unsafeAddr, size: sizeof(arr[0]) * arr.len)

converter toRangePtr*[T](data: var T): RangePtr =
  when T is string:
    RangePtr(head: data.cstring, size: data.len)
  elif compiles(data.rangePtrFromArray):
    data.rangePtrFromArray
  else:
    RangePtr(head: data.addr, size: sizeof(data))
converter toRangePtr*[T](data: T): RangePtr =
  when T is string:
    RangePtr(head: data.cstring, size: data.len)
  elif compiles(data.rangePtrFromArray):
    data.rangePtrFromArray
  else:
    RangePtr(head: data.unsafeAddr, size: sizeof(data))

template view*[T](data: MaybeVar[T]): ConstView[T] =
  when compiles(addr data):
    ConstView addr data
  else:
    ConstView unsafeAddr data
converter toConstView*[T](data: var T): ConstView[T] {.inline.} = ConstView addr data
converter toConstView*[T](data: ptr T): ConstView[T] {.inline.} = ConstView data

func whole*[T](data: openArray[T]): Slice[int] = 0..data.len

macro fixConstView*(fn: typed{nkProcDef}) =
  fn[4].expectKind nnkPragma
  var importcloc = -1
  var absImport = false
  for i, pv in fn[4].pairs:
    case pv.kind:
    of nnkIdent:
      if pv.strVal == "importc":
        importcloc = i
    of nnkExprColonExpr:
      if pv[0].strVal == "importc":
        absImport = true
        importcloc = i
    else:
      discard
  assert importcloc != -1, "expected importc"
  let idb = fn[0]
  let tid = if idb.kind == nnkPostfix: idb[1] else: idb
  let params = fn[3]
  var argnames: seq[NimNode]
  var paramsty: seq[NimNode]
  var needPatch = false
  for param in params[1..^1]:
    let pty = param[^2]
    let icv = pty.kind == nnkBracketExpr and pty[0] == bindSym "ConstView"
    if icv:
      needPatch = true
    else:
      paramsty.add param
    for name in param[0..^3]:
      if icv:
        let vname = nskParam.genSym name.strVal
        argnames.add newCall(bindSym "view", vname)
        paramsty.add nnkIdentDefs.newTree(
          vname,
          nnkBracketExpr.newTree(bindSym "MaybeVar", pty[1]),
          newEmptyNode()
        )
      else:
        argnames.add name
  result = newStmtList()
  let copied = copy fn
  let ret = copy fn
  let gname = nskProc.genSym tid.strVal
  copied[0] = gname
  if not absImport:
    copied[4][importcloc] = nnkExprColonExpr.newTree(ident "importc", newLit tid.strVal)
  ret[4].del importcloc
  ret[6] = newCall(gname)
  for name in argnames:
    ret[6].add name
  for i, ty in paramsty.pairs:
    ret[3][i + 1] = ty
  result.add copied
  result.add ret
