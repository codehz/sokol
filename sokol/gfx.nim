import ./private/backend
import ./common
from chroma import Color

export Color
export common

{.compile(
  "../upstream/sokol_gfx.h",
  "-x c -DSOKOL_IMPL -DSOKOL_" & sokol_backend
).}

type
  Buffer*   = distinct uint32
  Image*    = distinct uint32
  Shader*   = distinct uint32
  Pipeline* = distinct uint32
  Pass*     = distinct uint32
  Context*  = distinct uint32

const
  NUM_SHADER_STAGES       {.used.} = 2
  NUM_INFLIGHT_FRAMES     {.used.} = 2
  MAX_COLOR_ATTACHMENTS   {.used.} = 4
  MAX_SHADERSTAGE_BUFFERS {.used.} = 8
  MAX_SHADERSTAGE_IMAGES  {.used.} = 12
  MAX_SHADERSTAGE_UBS     {.used.} = 4
  MAX_UB_MEMBERS          {.used.} = 16
  MAX_VERTEX_ATTRIBUTES   {.used.} = 16
  MAX_MIPMAPS             {.used.} = 16
  MAX_TEXTUREARRAY_LAYERS {.used.} = 128

type
  Backend* = enum
    backend_glcore33
    backend_gles2
    backend_gles3
    backend_d3d11
    backend_metal_ios
    backend_metal_macos
    backend_metal_simulator
    backend_wgpu
    backend_dummy
  PixelFormatInfo* = object
    sample*, filter*, render*, blend*, msaa*, depth*: bool
  Features* = object
    instancing*: bool
    origin_top_left*: bool
    multiple_render_targets*: bool
    msaa_render_targets*: bool
    imagetype_3d*: bool
    imagetype_array*: bool
    image_clamp_to_border*: bool
    mrt_independent_blend_state*: bool
    mrt_independent_write_mask*: bool
  Limits* = object
    max_image_size_2d*: uint32
    max_image_size_cube*: uint32
    max_image_size_3d*: uint32
    max_image_size_array*: uint32
    max_image_array_layers*: uint32
    max_vertex_attrs*: uint32
    gl_max_vertex_uniform_vectors*: uint32
  ResourceState* {.pure, size: 4.} = enum
    rs_initial
    rs_alloc
    rs_valid
    rs_failed
    rs_invalid
  Usage* {.pure, size: 4.} = enum
    u_default
    u_immutable
    u_dynamic
    u_stream
  BufferKind* {.pure, size: 4.} = enum
    bk_default
    bk_vertex
    bk_index
  IndexKind* {.pure, size: 4.} = enum
    idx_default
    idx_none
    idx_uint16
    idx_uint32
  ImageKind* {.pure, size: 4.} = enum
    img_default
    img_2d
    img_cube
    img_3d
    img_array
  SamplerKind* {.pure, size: 4.} = enum
    sampler_default
    sampler_float
    sampler_sint
    sampler_uint
  CubeFace* {.pure, size: 4.} = enum
    cf_pos_x
    cf_neg_x
    cf_pos_y
    cf_neg_y
    cf_pos_z
    cf_neg_z
  ShaderStage* {.pure, size: 4.} = enum
    stage_vs
    stage_fs
  PrimitiveKind* {.pure, size: 4.} = enum
    pk_default
    pk_points
    pk_lines
    pk_line_strip
    pk_triangles
    pk_triangle_strip
  Filter* {.pure, size: 4.} = enum
    filter_default
    filter_nearest
    filter_linear
    filter_nearest_mipmap_nearest
    filter_nearest_mipmap_linear
    filter_linear_mipmap_nearest
    filter_linear_mipmap_linear
  Wrap* {.pure, size: 4.} = enum
    wrap_default
    wrap_repeat
    wrap_clamp_to_edge
    wrap_clamp_to_border
    wrap_mirrored_repeat
  BorderColor* {.pure, size: 4.} = enum
    border_default
    border_transparent_black
    border_opaque_black
    border_opaque_white
  VertexFormat* {.pure, size: 4.} = enum
    vf_invalid
    vf_float
    vf_float2
    vf_float3
    vf_float4
    vf_byte4
    vf_byte4n
    vf_ubyte4
    vf_ubyte4n
    vf_short2
    vf_short2n
    vf_ushort2n
    vf_short4
    vf_short4n
    vf_ushort4n
    vf_uint10_n2
  VertexStep* {.pure, size: 4.} = enum
    vs_default
    vs_per_vertex
    vs_per_instance
  UniformKind* {.pure, size: 4.} = enum
    u_invalid
    u_float
    u_float2
    u_float3
    u_float4
    u_mat4
  CullMode* {.pure, size: 4.} = enum
    cull_default
    cull_none
    cull_front
    cull_back
  FaceWinding* {.pure, size: 4.} = enum
    fw_default
    fw_ccw
    fw_cw
  CompareFuncHelper* = enum
    `==`, `!=`
    `<`, `>`
    `<=`, `>=`
  CompareFunc* {.pure, size: 4.} = enum
    cmp_default
    cmp_never
    cmp_less
    cmp_equal
    cmp_less_equal
    cmp_greater
    cmp_not_equal
    cmp_greater_equal
    cmp_always
  StencilOp* {.pure, size: 4.} = enum
    sop_default
    sop_keep
    sop_zero
    sop_replace
    sop_incr_clamp
    sop_decr_clamp
    sop_invert
    sop_incr_wrap
    sop_decr_wrap
  BlendFactor* {.pure, size: 4.} = enum
    blend_default
    blend_zero
    blend_one
    blend_src_color
    blend_one_minus_src_color
    blend_src_alpha
    blend_one_minus_src_alpha
    blend_dst_color
    blend_one_minus_dst_color
    blend_dst_alpha
    blend_one_minus_dst_alpha
    blend_src_alpha_saturated
    blend_blend_color
    blend_one_minus_blend_color
    blend_blend_alpha
    blend_one_minus_blend_alpha
  BlendOp* {.pure, size: 4.} = enum
    bop_default
    bop_add
    bop_subtract
    bop_reverse_subtract
  ColorMask* {.pure.} = enum
    cm_r
    cm_g
    cm_b
    cm_a
  ColorMasks* {.size: 4.} = set[ColorMask]
  ColorMaskInternal {.pure, size: 4.} = enum
    cmi_default
    cmi_r      = 0x1
    cmi_g      = 0x2
    cmi_rg     = 0x3
    cmi_b      = 0x4
    cmi_rb     = 0x5
    cmi_gb     = 0x6
    cmi_rgb    = 0x7
    cmi_a      = 0x8
    cmi_ra     = 0x9
    cmi_ga     = 0xa
    cmi_rga    = 0xb
    cmi_ba     = 0xc
    cmi_rba    = 0xd
    cmi_gba    = 0xe
    cmi_rgba   = 0xf
    cmi_none   = 0x10
  Action* {.pure, size: 4.} = enum
    action_default
    action_clear
    action_load
    action_dontcare
  ColorAttachmentAction* = object
    case action*: Action:
    of action_clear:
      color*: Color
    else:
      discard
  DepthAttachmentAction* = object
    action*: Action
    value*: float32
  StencilAttachmentAction* = object
    action*: Action
    value*: uint8
  PassAction* = object
    start_canary: uint32
    colors*: array[MAX_COLOR_ATTACHMENTS, ColorAttachmentAction]
    depth*: DepthAttachmentAction
    stencil*: StencilAttachmentAction
    end_canary: uint32
  Bindings* = object
    start_canary: uint32
    vertex_buffers*: array[MAX_SHADERSTAGE_BUFFERS, Buffer]
    vertex_buffer_offsets*: array[MAX_SHADERSTAGE_BUFFERS, int32]
    index_buffer*: Buffer
    index_buffer_offset*: int32
    vs_images*: array[MAX_SHADERSTAGE_IMAGES, Image]
    fs_images*: array[MAX_SHADERSTAGE_IMAGES, Image]
    end_canary: uint32
  BufferDesc* = object
    start_canary: uint32
    size*: csize_t
    kind*: BufferKind
    case usage*: Usage:
    of u_default, u_immutable:
      data*: RangePtr
    else:
      discard
    label*: cstring
    opengl*: array[NUM_INFLIGHT_FRAMES, uint32]
    metal*: array[NUM_INFLIGHT_FRAMES, pointer]
    d3d11*: pointer
    wgpu*: pointer
    end_canary: uint32
  ImageData* = object
    subimage*: array[CubeFace, array[MAX_MIPMAPS, RangePtr]]
  ImageDesc* = object
    start_canary: uint32
    kind*: ImageKind
    render_target*: bool
    width*, height*: uint32
    num_slices*, num_mipmaps*: uint32
    usage*: Usage
    pixel_format*: PixelFormat
    sample_count*: uint32
    min_filter*, mag_filter*: Filter
    wrap_u*, wrap_v*, wrap_w*: Wrap
    border_color*: BorderColor
    max_anisotropy*: uint32
    min_lod*, max_lod*: float32
    data*: ImageData
    label*: cstring
    opengl_textures*: array[NUM_INFLIGHT_FRAMES, uint32]
    opengl_target*: uint32
    metal_textures*: array[NUM_INFLIGHT_FRAMES, pointer]
    d3d11_texture*: pointer
    d3d11_shader_resource_view*: pointer
    wgpu_texture*: pointer
    end_canary: uint32
  ShaderAttributeDesc* = object
    name*: cstring
    sem_name*: cstring
    sem_index*: int32
  ShaderUniformDesc* = object
    name*: cstring
    kind*: UniformKind
    count*: uint32
  ShaderImageDesc* = object
    name*: cstring
    image_kind*: ImageKind
    sampler_kind*: SamplerKind
  ShaderUniformBlockDesc* = object
    size*: int
    uniforms*: array[MAX_UB_MEMBERS, ShaderUniformDesc]
  ShaderStageDesc* = object
    source*: cstring
    bytecode*: RangePtr
    entry*: cstring
    d3d11_target*: cstring
    uniform_blocks*: array[MAX_SHADERSTAGE_UBS, ShaderUniformBlockDesc]
    images*: array[MAX_SHADERSTAGE_IMAGES, ShaderImageDesc]
  ShaderDesc* = object
    start_canary: uint32
    attrs*: array[MAX_VERTEX_ATTRIBUTES, ShaderAttributeDesc]
    vs*, fs*: ShaderStageDesc
    label*: cstring
    end_canary: uint32
  BufferLayoutDesc* = object
    stride*: uint32
    step_func*: VertexStep
    step_rate*: uint32
  VertexAttributeDesc* = object
    buffer_index*: uint32
    offset*: uint32
    format*: VertexFormat
  LayoutDesc* = object
    buffers*: array[MAX_SHADERSTAGE_BUFFERS, BufferLayoutDesc]
    attrs*: array[MAX_VERTEX_ATTRIBUTES, VertexAttributeDesc]
  StencilFaceState* = object
    compare*: CompareFunc
    fail_op*, depth_fail_op*, pass_op*: StencilOp
  StencilState* = object
    case enabled*: bool
    of true:
      front*, back*: StencilFaceState
      read_mask*, write_mask*: uint8
      refc*: uint8
    else:
      discard
  DepthState* = object
    pixel_format*: PixelFormat
    compare*: CompareFunc
    write_enabled*: bool
    bias*, bias_slope_scale*, bias_clamp*: float32
  BlendState* = object
    case enabled*: bool
    of true:
      src_factor_rgb*, dst_factor_rgb*: BlendFactor
      op_rgb*: BlendOp
      src_factor_alpha*, dst_factor_alpha*: BlendFactor
      op_alpha*: BlendOp
    else:
      discard
  ColorState* = object
    pixel_format*: PixelFormat
    write_mask*: ColorMaskInternal
    blend*: BlendState
  PipelineDesc* = object
    start_canary: uint32
    shader*: Shader
    layout*: LayoutDesc
    depth*: DepthState
    stencil*: StencilState
    color_count*: uint32
    colors*: array[MAX_COLOR_ATTACHMENTS, ColorState]
    primitive_kind*: PrimitiveKind
    index_kind*: IndexKind
    cull_mode*: CullMode
    face_winding: FaceWinding
    sample_count*: uint32
    blend_color*: Color
    alpha_to_coverage_enabled*: bool
    label*: cstring
    end_canary: uint32
  PassAttachmentDesc* = object
    image*: Image
    mip_level*: uint32
    slice*: uint32
  PassDesc* = object
    start_canary: uint32
    color_atttachments*: array[MAX_COLOR_ATTACHMENTS, PassAttachmentDesc]
    depth_stencil_attachment*: PassAttachmentDesc
    label*: cstring
    end_canary: uint32
  TraceHooks* = object
    userdata*: pointer
    reset_state_cache*: proc (user: pointer) {.cdecl.}
    make_buffer*: proc (desc: ConstView[BufferDesc], result: Buffer, user: pointer) {.cdecl.}
    make_image*: proc (desc: ConstView[ImageDesc], result: Image, user: pointer) {.cdecl.}
    make_shader*: proc (desc: ConstView[ShaderDesc], result: Shader, user: pointer) {.cdecl.}
    make_pipeline*: proc (desc: ConstView[PipelineDesc], result: Pipeline, user: pointer) {.cdecl.}
    make_pass*: proc (desc: ConstView[PassDesc], result: Pass, user: pointer) {.cdecl.}
    destroy_buffer*: proc (target: Buffer, user: pointer) {.cdecl.}
    destroy_image*: proc (target: Image, user: pointer) {.cdecl.}
    destroy_shader*: proc (target: Shader, user: pointer) {.cdecl.}
    destroy_pipeline*: proc (target: Pipeline, user: pointer) {.cdecl.}
    destroy_pass*: proc (target: Pass, user: pointer) {.cdecl.}
    update_buffer*: proc (buf: Buffer, data: ConstView[RangePtr], user: pointer) {.cdecl.}
    update_image*: proc (img: Image, data: ConstView[ImageData], user: pointer) {.cdecl.}
    append_buffer*: proc (buf: Buffer, data: ConstView[RangePtr], user: pointer) {.cdecl.}
    begin_default_pass*: proc (action: PassAction, width, height: uint32, user: pointer) {.cdecl.}
    begin_pass*: proc (pass: Pass, action: PassAction, user: pointer) {.cdecl.}
    apply_viewport*: proc (x, y, width, height: int32, originTopLeft: bool, user: pointer) {.cdecl.}
    apply_scissor_rect*: proc (x, y, width, height: int32, originTopLeft: bool, user: pointer) {.cdecl.}
    apply_pipeline*: proc (pip: Pipeline, user: pointer) {.cdecl.}
    apply_bindings*: proc (bindings: ConstView[Bindings], user: pointer) {.cdecl.}
    apply_uniforms*: proc (stage: ShaderStage, ubIndex: uint32, data: ConstView[RangePtr], user: pointer) {.cdecl.}
    draw*: proc (baseElement, numElements, numInstances: uint32, user: pointer) {.cdecl.}
    end_pass*: proc (user: pointer) {.cdecl.}
    commit*: proc (user: pointer) {.cdecl.}
    alloc_buffer*: proc (result: Buffer, user: pointer) {.cdecl.}
    alloc_image*: proc (result: Image, user: pointer) {.cdecl.}
    alloc_shader*: proc (result: Shader, user: pointer) {.cdecl.}
    alloc_pipeline*: proc (result: Pipeline, user: pointer) {.cdecl.}
    alloc_pass*: proc (result: Pass, user: pointer) {.cdecl.}
    dealloc_buffer*: proc (target: Buffer, user: pointer) {.cdecl.}
    dealloc_image*: proc (target: Image, user: pointer) {.cdecl.}
    dealloc_shader*: proc (target: Shader, user: pointer) {.cdecl.}
    dealloc_pipeline*: proc (target: Pipeline, user: pointer) {.cdecl.}
    dealloc_pass*: proc (target: Pass, user: pointer) {.cdecl.}
    init_buffer*: proc (target: Buffer, desc: ConstView[BufferDesc], user: pointer) {.cdecl.}
    init_image*: proc (target: Image, desc: ConstView[ImageDesc], user: pointer) {.cdecl.}
    init_shader*: proc (target: Shader, desc: ConstView[ShaderDesc], user: pointer) {.cdecl.}
    init_pipeline*: proc (target: Pipeline, desc: ConstView[PipelineDesc], user: pointer) {.cdecl.}
    init_pass*: proc (target: Pass, desc: ConstView[PassDesc], user: pointer) {.cdecl.}
    uninit_buffer*: proc (target: Buffer, user: pointer) {.cdecl.}
    uninit_image*: proc (target: Image, user: pointer) {.cdecl.}
    uninit_shader*: proc (target: Shader, user: pointer) {.cdecl.}
    uninit_pipeline*: proc (target: Pipeline, user: pointer) {.cdecl.}
    uninit_pass*: proc (target: Pass, user: pointer) {.cdecl.}
    fail_buffer*: proc (target: Buffer, user: pointer) {.cdecl.}
    fail_image*: proc (target: Image, user: pointer) {.cdecl.}
    fail_shader*: proc (target: Shader, user: pointer) {.cdecl.}
    fail_pipeline*: proc (target: Pipeline, user: pointer) {.cdecl.}
    fail_pass*: proc (target: Pass, user: pointer) {.cdecl.}
    push_debug_group*: proc (name: cstring, user: pointer) {.cdecl.}
    pop_debug_group*: proc (user: pointer) {.cdecl.}
    err_buffer_pool_exhausted*: proc (user: pointer) {.cdecl.}
    err_image_pool_exhausted*: proc (user: pointer) {.cdecl.}
    err_shader_pool_exhausted*: proc (user: pointer) {.cdecl.}
    err_pipeline_pool_exhausted*: proc (user: pointer) {.cdecl.}
    err_pass_pool_exhausted*: proc (user: pointer) {.cdecl.}
    err_context_mismatch*: proc (user: pointer) {.cdecl.}
    err_pass_invalid*: proc (user: pointer) {.cdecl.}
    err_draw_invalid*: proc (user: pointer) {.cdecl.}
    err_bindings_invalid*: proc (user: pointer) {.cdecl.}
  SlotInfo* = object
    state*: ResourceState
    res_id*, ctx_id*: uint32
  BufferInfo* = object
    slot*: SlotInfo
    update_frame_index*, append_frame_index*: uint32
    append_pos*: uint32
    append_overflow*: bool
    num_slots*, active_slot*: uint32
  ImageInfo* = object
    slot*: SlotInfo
    update_frame_index*: uint32
    num_slots*, active_slot*: uint32
    width*, height*: uint32
  ShaderInfo* = object
    slot*: SlotInfo
  PipelineInfo* = object
    slot*: SlotInfo
  PassInfo* = object
    slot*: SlotInfo
  GlContextDesc* = object
    force_gles2*: bool
  MetalContextDesc* = object
    device*: pointer
    renderpass_descriptor*: proc: pointer {.cdecl.}
    renderpass_descriptor_userdata*: proc: pointer {.cdecl.}
    drawable*: proc: pointer {.cdecl.}
    drawable_userdata*: proc: pointer {.cdecl.}
    userdata*: pointer
  D3d11ContextDesc* = object
    device*, device_context*: pointer
    render_target_view*: proc: pointer {.cdecl.}
    render_target_view_userdata*: proc: pointer {.cdecl.}
    depth_stencil_view*: proc: pointer {.cdecl.}
    depth_stencil_view_userdata*: proc: pointer {.cdecl.}
    userdata*: pointer
  WgpuContextDesc* = object
    device*: pointer
    render_view*: proc: pointer {.cdecl.}
    render_view_userdata*: proc: pointer {.cdecl.}
    resolve_view*: proc: pointer {.cdecl.}
    resolve_view_userdata*: proc: pointer {.cdecl.}
    depth_stencil_view*: proc: pointer {.cdecl.}
    depth_stencil_view_userdata*: proc: pointer {.cdecl.}
    userdata*: pointer
  ContextDesc* = object
    color_format*, depth_format*: PixelFormat
    sample_count*: uint32
    gl*: GlContextDesc
    metal*: MetalContextDesc
    d3d11*: D3d11ContextDesc
    wgpu*: WgpuContextDesc
  Desc* = object
    start_canary: uint32
    buffer_pool_size*: uint32
    image_pool_size*: uint32
    shader_pool_size*: uint32
    pipeline_pool_size*: uint32
    pass_pool_size*: uint32
    context_pool_size*: uint32
    uniform_pool_size*: uint32
    staging_pool_size*: uint32
    context*: ContextDesc
    end_canary: uint32

converter toCompareFunc*(helper: CompareFuncHelper): CompareFunc =
  case helper:
  of `==`: cmp_equal
  of `!=`: cmp_not_equal
  of `<` : cmp_less
  of `>` : cmp_greater
  of `<=`: cmp_less_equal
  of `>=`: cmp_greater_equal

converter toColorMaskInternal*(mask: ColorMasks): ColorMaskInternal =
  var c = 0
  if cm_r in mask: c += 1
  if cm_g in mask: c += 2
  if cm_b in mask: c += 4
  if cm_a in mask: c += 8
  if c == 0: c = 16
  cast[ColorMaskInternal](c)

proc make*(desc: ConstView[BufferDesc])  : Buffer   {.fixConstView, importc: "sg_make_buffer".}
proc make*(desc: ConstView[ImageDesc])   : Image    {.fixConstView, importc: "sg_make_image".}
proc make*(desc: ConstView[ShaderDesc])  : Shader   {.fixConstView, importc: "sg_make_shader".}
proc make*(desc: ConstView[PipelineDesc]): Pipeline {.fixConstView, importc: "sg_make_pipeline".}
proc make*(desc: ConstView[PassDesc])    : Pass     {.fixConstView, importc: "sg_make_pass".}
proc destroy*(target: Buffer)   {.importc: "sg_destroy_buffer".}
proc destroy*(target: Image)    {.importc: "sg_destroy_image".}
proc destroy*(target: Shader)   {.importc: "sg_destroy_shader".}
proc destroy*(target: Pipeline) {.importc: "sg_destroy_pipeline".}
proc destroy*(target: Pass)     {.importc: "sg_destroy_pass".}
proc update*(buf: Buffer, data: ConstView[RangePtr]) {.fixConstView, importc: "sg_update_buffer".}
proc update*(img: Image, data: ConstView[ImageData]) {.fixConstView, importc: "sg_update_image".}
proc append*(buf: Buffer, data: ConstView[RangePtr]) {.fixConstView, importc: "sg_append_buffer".}
proc state*(target: Buffer)  : ResourceState {.importc: "sg_query_buffer_state".}
proc state*(target: Image)   : ResourceState {.importc: "sg_query_image_state".}
proc state*(target: Shader)  : ResourceState {.importc: "sg_query_shader_state".}
proc state*(target: Pipeline): ResourceState {.importc: "sg_query_pipeline_state".}
proc state*(target: Pass)    : ResourceState {.importc: "sg_query_pass_state".}
proc info*(target: Buffer)  : BufferInfo   {.importc: "sg_query_buffer_info".}
proc info*(target: Image)   : ImageInfo    {.importc: "sg_query_image_info".}
proc info*(target: Shader)  : ShaderInfo   {.importc: "sg_query_shader_info".}
proc info*(target: Pipeline): PipelineInfo {.importc: "sg_query_pipeline_info".}
proc info*(target: Pass)    : PassInfo     {.importc: "sg_query_pass_info".}
proc defaults*(desc: ConstView[BufferDesc])  : BufferDesc   {.fixConstView, importc: "sg_query_buffer_defaults".}
proc defaults*(desc: ConstView[ImageDesc])   : ImageDesc    {.fixConstView, importc: "sg_query_image_defaults".}
proc defaults*(desc: ConstView[ShaderDesc])  : ShaderDesc   {.fixConstView, importc: "sg_query_shader_defaults".}
proc defaults*(desc: ConstView[PipelineDesc]): PipelineDesc {.fixConstView, importc: "sg_query_pipeline_defaults".}
proc defaults*(desc: ConstView[PassDesc])    : PassDesc     {.fixConstView, importc: "sg_query_pass_defaults".}
proc dealloc*(target: Buffer)   {.importc: "sg_dealloc_buffer".}
proc dealloc*(target: Image)    {.importc: "sg_dealloc_image".}
proc dealloc*(target: Shader)   {.importc: "sg_dealloc_shader".}
proc dealloc*(target: Pipeline) {.importc: "sg_dealloc_pipeline".}
proc dealloc*(target: Pass)     {.importc: "sg_dealloc_pass".}
proc init*(target: Buffer,   desc: ConstView[BufferDesc])   {.fixConstView, importc: "sg_init_buffer".}
proc init*(target: Image,    desc: ConstView[ImageDesc])    {.fixConstView, importc: "sg_init_image".}
proc init*(target: Shader,   desc: ConstView[ShaderDesc])   {.fixConstView, importc: "sg_init_shader".}
proc init*(target: Pipeline, desc: ConstView[PipelineDesc]) {.fixConstView, importc: "sg_init_pipeline".}
proc init*(target: Pass,     desc: ConstView[PassDesc])     {.fixConstView, importc: "sg_init_pass".}
proc uninit*(target: Buffer)  : bool {.importc: "sg_uninit_buffer".}
proc uninit*(target: Image)   : bool {.importc: "sg_uninit_image".}
proc uninit*(target: Shader)  : bool {.importc: "sg_uninit_shader".}
proc uninit*(target: Pipeline): bool {.importc: "sg_uninit_pipeline".}
proc uninit*(target: Pass)    : bool {.importc: "sg_uninit_pass".}
proc fail*(target: Buffer)   {.importc: "sg_fail_buffer".}
proc fail*(target: Image)    {.importc: "sg_fail_image".}
proc fail*(target: Shader)   {.importc: "sg_fail_shader".}
proc fail*(target: Pipeline) {.importc: "sg_fail_pipeline".}
proc fail*(target: Pass)     {.importc: "sg_fail_pass".}
proc apply*(pip: Pipeline) {.importc: "sg_apply_pipeline".}
proc apply*(bindings: ConstView[Bindings]) {.fixConstView, importc: "sg_apply_bindings".}

proc sg_draw(baseElement, numElements, numInstances: uint32) {.importc.}

proc draw*[T, U, I: Ordinal](elements: HSlice[T, U], instances: I = 1) =
  sg_draw(uint32 elements.a, uint32 elements.b, uint32 instances)

proc setup*(desc: ConstView[Desc]) {.importc: "sg_$1", fixConstView.}
proc install_trace_hooks*(hooks: ConstView[TraceHooks]) {.importc: "sg_$1", fixConstView.}
proc apply_uniforms*(stage: ShaderStage, ubIndex: uint32, data: ConstView[RangePtr]) {.importc: "sg_$1", fixConstView.}

{.push importc: "sg_$1", cdecl.}
proc shutdown*
proc isvalid*: bool
proc reset_state_cach*
proc pushDebugGroup*(name: cstring)
proc popDebugGroup*

proc query_buffer_overflow*(buf: Buffer)

proc begin_default_pass*(action: PassAction, width, height: uint32)
proc begin_default_passf*(action: PassAction, width, height: float32)
proc begin_pass*(pass: Pass, action: PassAction)
proc apply_viewport*(x, y, width, height: int32, originTopLeft: bool)
proc apply_viewportf*(x, y, width, height: float32, originTopLeft: bool)
proc apply_scissor_rect*(x, y, width, height: int32, originTopLeft: bool)
proc apply_scissor_rectf*(x, y, width, height: float32, originTopLeft: bool)
# proc draw*(baseElement, numElements, numInstances: uint32)
proc end_pass*
proc commit*

proc query_desc*: Desc
proc query_backend*: Backend
proc query_features*: Features
proc query_limits*: Limits
proc query_pixelformat*(fmt: PixelFormat): PixelFormatInfo

proc alloc_buffer()  : Buffer
proc alloc_image()   : Image
proc alloc_shader()  : Shader
proc alloc_pipeline(): Pipeline
proc alloc_pass()    : Pass

proc setup_context*: Context
proc activate_context*(ctxId: Context)
proc discard_context*(ctxId: Context)

proc d3d11_device*: pointer
proc mtl_device*: pointer
proc mtl_render_command_encoder*: pointer
{.pop.}

proc alloc*(_: typedesc[Buffer]):   Buffer   = alloc_buffer()
proc alloc*(_: typedesc[Image]):    Image    = alloc_image()
proc alloc*(_: typedesc[Shader]):   Shader   = alloc_shader()
proc alloc*(_: typedesc[Pipeline]): Pipeline = alloc_pipeline()
proc alloc*(_: typedesc[Pass]):     Pass     = alloc_pass()

template default_pass*(action: PassAction, width, height: uint32, body: untyped) =
  begin_default_pass(action, width, height)
  try:
    body
  finally:
    end_pass()

template default_pass*(action: PassAction, width, height: float32, body: untyped) =
  begin_default_passf(action, width, height)
  try:
    body
  finally:
    end_pass()

template begin*(pass: Pass, action: PassAction) =
  begin_pass(pass, action)
  try:
    body
  finally:
    end_pass()

func defineShaderDesc*(
  label: cstring;
  attr: openarray[ShaderAttributeDesc];
  vs, fs: ShaderStageDesc;
): ShaderDesc =
  assert attr.len <= MAX_VERTEX_ATTRIBUTES
  result = ShaderDesc(label: label, vs: vs, fs: fs)
  for i, a in attr.pairs:
    result.attrs[i] = a

type PassState* = object
  action*: PassAction
  pipeline*: Pipeline
  bindings*: Bindings