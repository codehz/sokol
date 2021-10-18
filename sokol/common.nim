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

converter toRangePtr*[l, T](data: var array[l, T]): RangePtr = RangePtr(head: data.addr, size: sizeof(data))
converter toRangePtr*(data: openArray[byte]): RangePtr = RangePtr(head: data.unsafeAddr, size: data.len)
converter toRangePtr*(data: var string): RangePtr = RangePtr(head: data.cstring, size: data.len)

converter toConstView*[T](data: T): ConstView[T] {.inline.} = ConstView unsafeAddr data
converter toConstView*[T](data: var T): ConstView[T] {.inline.} = ConstView addr data
converter toConstView*[T](data: ptr T): ConstView[T] {.inline.} = ConstView data
