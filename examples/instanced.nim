import sokol/[app, gfx, glue, tools, utils]
import chroma, vmath
import cascade

importshader "instanced.glsl"

type
  Vertex {.step: 1.} = object
    position {.underlying: array[3, float32].}: Vec3
    color0 {.underlying: array[4, float32].}: Color
  Instance {.instance.} = object
    offset {.underlying: array[3, float32].}: Vec3

let vertices = [
  Vertex(position: vec3(0.0f,  0.5f, 0.5f),  color0: color(1, 0, 0)),
  Vertex(position: vec3(0.5f, -0.5f, 0.5f),  color0: color(0, 1, 0)),
  Vertex(position: vec3(-0.5f, -0.5f, 0.5f), color0: color(0, 0, 1)),
]
let offsets = [
  Instance(offset: vec3(0, -1, 0)),
  Instance(offset: vec3(-1, 0, 0)),
  Instance(offset: vec3(-1, -1, 0)),
  Instance(offset: vec3(0, 0, 0)),
  Instance(offset: vec3(0, 1, 0)),
  Instance(offset: vec3(1, 0, 0)),
  Instance(offset: vec3(1, 1, 0)),
  Instance(offset: vec3(1, -1, 0)),
  Instance(offset: vec3(-1, 1, 0)),
]
const layout = triangle.layout(Vertex, Instance)

delayinit bindings, Bindings:
  bindings.vertex_buffers[0] = gfx.make BufferDesc(data: vertices, label: "instanced-vertices")
  bindings.vertex_buffers[1] = gfx.make BufferDesc(data: offsets, label: "instanced-instance")
delayinit pipeline: gfx.make PipelineDesc(
  shader: gfx.make triangle,
  layout: layout,
  label: "instanced-pipeline"
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
      gfx.draw(whole vertices, offsets.len)
    gfx.commit()
  cleanup = proc {.cdecl.} =
    gfx.shutdown()
  high_dpi = true
  window_title = "instanced"

quit app_desc.start()