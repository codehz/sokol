import ./private/backend
import ./common
from chroma import Color

export Color

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
  ColorMask* {.pure, size: 4.} = enum
    cm_default
    cm_r      = 0x1
    cm_g      = 0x2
    cm_rg     = 0x3
    cm_b      = 0x4
    cm_rb     = 0x5
    cm_gb     = 0x6
    cm_rgb    = 0x7
    cm_a      = 0x8
    cm_ra     = 0x9
    cm_ga     = 0xa
    cm_rga    = 0xb
    cm_ba     = 0xc
    cm_rba    = 0xd
    cm_gba    = 0xe
    cm_rgba   = 0xf
    cm_none   = 0x10
  Action* {.pure, size: 4.} = enum
    action_default
    action_clear
    action_load
    action_dontcare
  ColorAttachmentAction* = object
    action: Action
    color: Color
  DepthAttachmentAction* = object
    action: Action
    value: float32
  StencilAttachmentAction* = object
    action: Action
    value: uint8
  PassAction* = object
    startCanary: uint32
    colors*: array[MAX_COLOR_ATTACHMENTS, ColorAttachmentAction]
    depth*: DepthAttachmentAction
    stencil*: StencilAttachmentAction
    endCanary: uint32
  Bindings* = object
    startCanary: uint32
    vertexBuffers*: array[MAX_SHADERSTAGE_BUFFERS, Buffer]
    vertexBufferOffsets*: array[MAX_SHADERSTAGE_BUFFERS, int32]
    indexBuffer*: Buffer
    indexBufferOffset*: int32
    vsImages*: array[MAX_SHADERSTAGE_IMAGES, Image]
    fsImages*: array[MAX_SHADERSTAGE_IMAGES, Image]
    endCanary: uint32
  BufferDesc* = object
    startCanary: uint32
    size*: csize_t
    kind*: BufferKind
    usage*: Usage
    data*: RangePtr
    label*: cstring
    opengl*: array[NUM_INFLIGHT_FRAMES, uint32]
    metal*: array[NUM_INFLIGHT_FRAMES, pointer]
    d3d11*: pointer
    wgpu*: pointer
    endCanary: uint32
  ImageData* = object
    subimage*: array[CubeFace, array[MAX_MIPMAPS, RangePtr]]
  ImageDesc* = object
    startCanary: uint32
    kind*: ImageKind
    renderTarget*: bool
    width*, height*: uint32
    numSlices*, numMipmaps*: uint32
    usage*: Usage
    pixelFormat*: PixelFormat
    sampleCount*: uint32
    minFilter*, magFilter*: Filter
    wrapU*, wrapV*, wrapW*: Wrap
    borderColor*: BorderColor
    maxAnisotropy*: uint32
    minLod*, maxLod*: float32
    data*: ImageData
    label*: cstring
    openglTextures*: array[NUM_INFLIGHT_FRAMES, uint32]
    openglTarget*: uint32
    metalTextures*: array[NUM_INFLIGHT_FRAMES, pointer]
    d3d11Texture*: pointer
    d3d11ShaderResourceView*: pointer
    wgpuTexture*: pointer
    endCanary: uint32
  ShaderAttributeDesc* = object
    name*: cstring
    semName*: cstring
    semIndex*: int32
  ShaderUniformDesc* = object
    name*: cstring
    kind*: UniformKind
    count*: uint32
  ShaderUniformBlockDesc* = object
    name*: cstring
    imageKind*: ImageKind
    samplerKind*: SamplerKind
  ShaderStageDesc* = object
    source*: cstring
    bytecode*: RangePtr
    entry*: cstring
    d3d11Target*: cstring
    uniformBlocks*: array[MAX_SHADERSTAGE_UBS, ShaderUniformBlockDesc]
    images*: array[MAX_SHADERSTAGE_IMAGES, ImageDesc]
  ShaderDesc* = object
    startCanary: uint32
    attr*: array[MAX_VERTEX_ATTRIBUTES, ShaderAttributeDesc]
    vs*, fs*: ShaderStageDesc
    label*: cstring
    endCanary: uint32
  BufferLayoutDesc* = object
    stride*: uint32
    stepFunc*: VertexStep
    stepRate*: uint32
  VertexAttributeDesc* = object
    bufferIndex*: uint32
    offset*: uint32
    format*: VertexFormat
  LayoutDesc* = object
    buffers*: array[MAX_SHADERSTAGE_BUFFERS, BufferLayoutDesc]
    attrs*: array[MAX_VERTEX_ATTRIBUTES, VertexAttributeDesc]
  StencilFaceState* = object
    compare*: CompareFunc
    failOp*, depthFailOp*, passOp*: StencilOp
  StencilState* = object
    enabled*: bool
    front*, back*: StencilFaceState
    readMask*, writeMask*: uint8
    refc*: uint8
  DepthState* = object
    pixelFormat*: PixelFormat
    compare*: CompareFunc
    writeEnabled*: bool
    bias*, biasSlopeScale*, biasClamp*: float32
  BlendState* = object
    enabled*: bool
    srcFactorRgb*, dstFactorRgb*: BlendFactor
    opRgb*: BlendOp
    srcFactorAlpha*, dstFactorAlpha*: BlendFactor
    opAlpha*: BlendOp
  ColorState* = object
    pixelFormat*: PixelFormat
    writeMask*: ColorMask
    blend*: BlendState
  PipelineDesc* = object
    startCanary: uint32
    shader*: Shader
    layout*: LayoutDesc
    depth*: DepthState
    stencil*: StencilState
    colorCount*: uint32
    colors*: array[MAX_COLOR_ATTACHMENTS, ColorState]
    primitiveKind*: PrimitiveKind
    indexKind*: IndexKind
    cullMode*: CullMode
    faceWinding: FaceWinding
    sampleCount*: uint32
    blendColor*: Color
    alphaToCoverageEnabled*: bool
    label*: cstring
    endCanary: uint32
  PassAttachmentDesc* = object
    image*: Image
    mipLevel*: uint32
    slice*: uint32
  PassDesc* = object
    startCanary: uint32
    colorAtttachments*: array[MAX_COLOR_ATTACHMENTS, PassAttachmentDesc]
    depthStencilAttachment*: PassAttachmentDesc
    label*: cstring
    endCanary: uint32
  TraceHooks* = object
    userData*: pointer
    resetStateCache*: proc (user: pointer) {.cdecl.}
    makeBuffer*: proc (desc: ConstView[BufferDesc], result: Buffer, user: pointer) {.cdecl.}
    makeImage*: proc (desc: ConstView[ImageDesc], result: Image, user: pointer) {.cdecl.}
    makeShader*: proc (desc: ConstView[ShaderDesc], result: Shader, user: pointer) {.cdecl.}
    makePipeline*: proc (desc: ConstView[PipelineDesc], result: Pipeline, user: pointer) {.cdecl.}
    makePass*: proc (desc: ConstView[PassDesc], result: Pass, user: pointer) {.cdecl.}
    destroyBuffer*: proc (target: Buffer, user: pointer) {.cdecl.}
    destroyImage*: proc (target: Image, user: pointer) {.cdecl.}
    destroyShader*: proc (target: Shader, user: pointer) {.cdecl.}
    destroyPipeline*: proc (target: Pipeline, user: pointer) {.cdecl.}
    destroyPass*: proc (target: Pass, user: pointer) {.cdecl.}
    updateBuffer*: proc (buf: Buffer, data: ConstView[RangePtr], user: pointer) {.cdecl.}
    updateImage*: proc (img: Image, data: ConstView[ImageData], user: pointer) {.cdecl.}
    appendBuffer*: proc (buf: Buffer, data: ConstView[RangePtr], user: pointer) {.cdecl.}
    beginDefaultPass*: proc (action: PassAction, width, height: uint32, user: pointer) {.cdecl.}
    beginPass*: proc (pass: Pass, action: PassAction, user: pointer) {.cdecl.}
    applyViewport*: proc (x, y, width, height: int32, originTopLeft: bool, user: pointer) {.cdecl.}
    applyScissorRect*: proc (x, y, width, height: int32, originTopLeft: bool, user: pointer) {.cdecl.}
    applyPipeline*: proc (pip: Pipeline, user: pointer) {.cdecl.}
    applyBindings*: proc (bindings: ConstView[Bindings], user: pointer) {.cdecl.}
    applyUniforms*: proc (stage: ShaderStage, ubIndex: uint32, data: ConstView[RangePtr], user: pointer) {.cdecl.}
    draw*: proc (baseElement, numElements, numInstances: uint32, user: pointer) {.cdecl.}
    endPass*: proc (user: pointer) {.cdecl.}
    commit*: proc (user: pointer) {.cdecl.}
    allocBuffer*: proc (result: Buffer, user: pointer) {.cdecl.}
    allocImage*: proc (result: Image, user: pointer) {.cdecl.}
    allocShader*: proc (result: Shader, user: pointer) {.cdecl.}
    allocPipeline*: proc (result: Pipeline, user: pointer) {.cdecl.}
    allocPass*: proc (result: Pass, user: pointer) {.cdecl.}
    deallocBuffer*: proc (target: Buffer, user: pointer) {.cdecl.}
    deallocImage*: proc (target: Image, user: pointer) {.cdecl.}
    deallocShader*: proc (target: Shader, user: pointer) {.cdecl.}
    deallocPipeline*: proc (target: Pipeline, user: pointer) {.cdecl.}
    deallocPass*: proc (target: Pass, user: pointer) {.cdecl.}
    initBuffer*: proc (target: Buffer, desc: ConstView[BufferDesc], user: pointer) {.cdecl.}
    initImage*: proc (target: Image, desc: ConstView[ImageDesc], user: pointer) {.cdecl.}
    initShader*: proc (target: Shader, desc: ConstView[ShaderDesc], user: pointer) {.cdecl.}
    initPipeline*: proc (target: Pipeline, desc: ConstView[PipelineDesc], user: pointer) {.cdecl.}
    initPass*: proc (target: Pass, desc: ConstView[PassDesc], user: pointer) {.cdecl.}
    uninitBuffer*: proc (target: Buffer, user: pointer) {.cdecl.}
    uninitImage*: proc (target: Image, user: pointer) {.cdecl.}
    uninitShader*: proc (target: Shader, user: pointer) {.cdecl.}
    uninitPipeline*: proc (target: Pipeline, user: pointer) {.cdecl.}
    uninitPass*: proc (target: Pass, user: pointer) {.cdecl.}
    failBuffer*: proc (target: Buffer, user: pointer) {.cdecl.}
    failImage*: proc (target: Image, user: pointer) {.cdecl.}
    failShader*: proc (target: Shader, user: pointer) {.cdecl.}
    failPipeline*: proc (target: Pipeline, user: pointer) {.cdecl.}
    failPass*: proc (target: Pass, user: pointer) {.cdecl.}
    pushDebugGroup*: proc (name: cstring, user: pointer) {.cdecl.}
    popDebugGroup*: proc (user: pointer) {.cdecl.}
    errBufferPoolExhausted*: proc (user: pointer) {.cdecl.}
    errImagePoolExhausted*: proc (user: pointer) {.cdecl.}
    errShaderPoolExhausted*: proc (user: pointer) {.cdecl.}
    errPipelinePoolExhausted*: proc (user: pointer) {.cdecl.}
    errPassPoolExhausted*: proc (user: pointer) {.cdecl.}
    errContextMismatch*: proc (user: pointer) {.cdecl.}
    errPassInvalid*: proc (user: pointer) {.cdecl.}
    errDrawInvalid*: proc (user: pointer) {.cdecl.}
    errBindingsInvalid*: proc (user: pointer) {.cdecl.}
  SlotInfo* = object
    state*: ResourceState
    resId*, ctxId*: uint32
  BufferInfo* = object
    slot*: SlotInfo
    updateFrameIndex*, appendFrameIndex*: uint32
    appendPos*: uint32
    appendOverflow*: bool
    numSlots*, activeSlot*: uint32
  ImageInfo* = object
    slot*: SlotInfo
    updateFrameIndex*: uint32
    numSlots*, activeSlot*: uint32
    width*, height*: uint32
  ShaderInfo* = object
    slot*: SlotInfo
  PipelineInfo* = object
    slot*: SlotInfo
  PassInfo* = object
    slot*: SlotInfo
  GlContextDesc* = object
    forceGles2*: bool
  MetalContextDesc* = object
    device*: pointer
    renderpassDescriptor*: proc: pointer {.cdecl.}
    renderpassDescriptorUserdata*: proc: pointer {.cdecl.}
    drawable*: proc: pointer {.cdecl.}
    drawableUserdata*: proc: pointer {.cdecl.}
    userData*: pointer
  D3d11ContextDesc* = object
    device*: pointer
    renderTargetView*: proc: pointer {.cdecl.}
    renderTargetViewUserdata*: proc: pointer {.cdecl.}
    depthStencilView*: proc: pointer {.cdecl.}
    depthStencilViewUserdata*: proc: pointer {.cdecl.}
    userData*: pointer
  WgpuContextDesc* = object
    device*: pointer
    renderView*: proc: pointer {.cdecl.}
    renderViewUserdata*: proc: pointer {.cdecl.}
    resolveView*: proc: pointer {.cdecl.}
    resolveViewUserdata*: proc: pointer {.cdecl.}
    depthStencilView*: proc: pointer {.cdecl.}
    depthStencilViewUserdata*: proc: pointer {.cdecl.}
    userData*: pointer
  ContextDesc* = object
    colorFormat*, depthFormat*: PixelFormat
    sampleCount*: uint32
    gl*: GlContextDesc
    metal*: MetalContextDesc
    d3d11*: D3d11ContextDesc
    wgpu*: WgpuContextDesc
  Desc* = object
    startCanary: uint32
    bufferPoolSize*: uint32
    imagePoolSize*: uint32
    shaderPoolSize*: uint32
    pipelinePoolSize*: uint32
    passPoolSize*: uint32
    contextPoolSize*: uint32
    uniformPoolSize*: uint32
    stagingPoolSize*: uint32
    context*: ContextDesc
    endCanary: uint32

{.push importc: "sg_$1", cdecl.}
proc setup*(desc: ConstView[Desc])
proc shutdown*
proc isvalid*: bool
proc reset_state_cach*
proc install_trace_hooks*(hooks: ConstView[TraceHooks])
proc pushDebugGroup*(name: cstring)
proc popDebugGroup*

proc make*(desc: ConstView[BufferDesc])  : Buffer   {.importc: "sg_make_buffer".}
proc make*(desc: ConstView[ImageDesc])   : Image    {.importc: "sg_make_image".}
proc make*(desc: ConstView[ShaderDesc])  : Shader   {.importc: "sg_make_shader".}
proc make*(desc: ConstView[PipelineDesc]): Pipeline {.importc: "sg_make_pipeline".}
proc make*(desc: ConstView[PassDesc])    : Pass     {.importc: "sg_make_pass".}
proc destroy*(target: Buffer)   {.importc: "sg_destroy_buffer".}
proc destroy*(target: Image)    {.importc: "sg_destroy_image".}
proc destroy*(target: Shader)   {.importc: "sg_destroy_shader".}
proc destroy*(target: Pipeline) {.importc: "sg_destroy_pipeline".}
proc destroy*(target: Pass)     {.importc: "sg_destroy_pass".}
proc update*(buf: Buffer, data: ConstView[RangePtr]) {.importc: "sg_update_buffer".}
proc update*(img: Image, data: ConstView[ImageData]) {.importc: "sg_update_image".}
proc append*(buf: Buffer, data: ConstView[RangePtr]) {.importc: "sg_append_buffer".}
proc query_buffer_overflow*(buf: Buffer)

proc begin_default_pass*(action: PassAction, width, height: uint32)
proc begin_default_passf*(action: PassAction, width, height: float32)
proc begin_pass*(pass: Pass, action: PassAction)
proc apply_viewport*(x, y, width, height: int32, originTopLeft: bool)
proc apply_viewportf*(x, y, width, height: float32, originTopLeft: bool)
proc apply_scissor_rect*(x, y, width, height: int32, originTopLeft: bool)
proc apply_scissor_rectf*(x, y, width, height: float32, originTopLeft: bool)
proc apply_pipeline*(pip: Pipeline)
proc apply_bindings*(bindings: ConstView[Bindings])
proc apply_uniforms*(stage: ShaderStage, ubIndex: uint32, data: ConstView[RangePtr])
proc draw*(baseElement, numElements, numInstances: uint32)
proc end_pass*
proc commit*

proc query_desc*: Desc
proc query_backend*: Backend
proc query_features*: Features
proc query_limits*: Limits
proc query_pixelformat*(fmt: PixelFormat): PixelFormatInfo
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
proc defaults*(desc: ConstView[BufferDesc])  : BufferDesc   {.importc: "sg_query_buffer_defaults".}
proc defaults*(desc: ConstView[ImageDesc])   : ImageDesc    {.importc: "sg_query_image_defaults".}
proc defaults*(desc: ConstView[ShaderDesc])  : ShaderDesc   {.importc: "sg_query_shader_defaults".}
proc defaults*(desc: ConstView[PipelineDesc]): PipelineDesc {.importc: "sg_query_pipeline_defaults".}
proc defaults*(desc: ConstView[PassDesc])    : PassDesc     {.importc: "sg_query_pass_defaults".}

proc alloc_buffer*(): Buffer
proc alloc_image*(): Image
proc alloc_shader*(): Shader
proc alloc_pipeline*(): Pipeline
proc alloc_pass*(): Pass
proc dealloc*(target: Buffer)   {.importc: "sg_dealloc_buffer".}
proc dealloc*(target: Image)    {.importc: "sg_dealloc_image".}
proc dealloc*(target: Shader)   {.importc: "sg_dealloc_shader".}
proc dealloc*(target: Pipeline) {.importc: "sg_dealloc_pipeline".}
proc dealloc*(target: Pass)     {.importc: "sg_dealloc_pass".}
proc init*(target: Buffer,   desc: ConstView[BufferDesc])   {.importc: "sg_init_buffer".}
proc init*(target: Image,    desc: ConstView[ImageDesc])    {.importc: "sg_init_image".}
proc init*(target: Shader,   desc: ConstView[ShaderDesc])   {.importc: "sg_init_shader".}
proc init*(target: Pipeline, desc: ConstView[PipelineDesc]) {.importc: "sg_init_pipeline".}
proc init*(target: Pass,     desc: ConstView[PassDesc])     {.importc: "sg_init_pass".}
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

proc setup_context*: Context
proc activate_context*(ctxId: Context)
proc discard_context*(ctxId: Context)

proc d3d11_device*: pointer
proc mtl_device*: pointer
proc mtl_render_command_encoder*: pointer
{.pop.}