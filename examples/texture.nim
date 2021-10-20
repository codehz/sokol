import sokol/[app, gfx, glue, tools, utils]
import chroma, vmath
import cascade

importshader "texture.glsl"

type
  Vertex {.step: 1.} = object
    position {.underlying: array[3, float32].}: Vec3
    uv {.underlying: array[2, float32].}: Vec2

let vertices = [
  Vertex(position: vec3(0, 0, 0.5), uv: vec2(1, 0)),
  Vertex(position: vec3(0, 1, 0.5), uv: vec2(0, 1)),
  Vertex(position: vec3(1, 0, 0.5), uv: vec2(1, 0)),
  Vertex(position: vec3(1, 1, 0.5), uv: vec2(1, 1)),
]
let indices = [0'u16, 1, 2, 2, 1, 3]
const layout = triangle.layout Vertex

var bufferdesc = BufferDesc(data: vertices, label: "texture-vertices")
var indexdesc = BufferDesc(data: indices, kind: bk_index, label: "texture-indices")
var imgrawdata: array[100 * 100, array[4, byte]]
var imgdata: ImageData
imgdata.subimage[cf_pos_x][0] = imgrawdata
for c in imgrawdata.mitems():
  c[0] = 255
  c[3] = 255
delayinit img: gfx.make ImageDesc(
  width: 100,
  height: 100,
  pixel_format: pf_rgba8,
  data: imgdata
)
delayinit bindings, Bindings:
  bindings.vertex_buffers[0] = gfx.make bufferdesc
  bindings.index_buffer = gfx.make indexdesc
  bindings.fs_images[0] = img
delayinit shd: gfx.make triangle
delayinit pipeline: gfx.make PipelineDesc(
  shader: shd,
  layout: layout,
  index_kind: idx_uint16,
  label: "texture-pipeline"
)
var passAction: PassAction
passAction.colors[0] = ColorAttachmentAction(action: action_clear, color: color(1, 1, 1))

let app_desc = cascade AppDesc():
  init = proc {.cdecl.} =
    gfx.setup Desc(context: gfx_context())
    doinit()
  frame = proc {.cdecl.} =
    default_pass passAction, width(), height():
      pipeline.apply
      bindings.apply
      gfx.draw(whole indices)
    gfx.commit()
  cleanup = proc {.cdecl.} =
    gfx.shutdown()
  high_dpi = true
  window_title = "texture"

quit app_desc.start()