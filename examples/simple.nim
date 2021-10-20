import sokol/[app, gfx, glue, tools, utils]
import chroma, vmath
import cascade

importshader "simple.glsl"

type
  Vertex {.step: 1.} = object
    position {.underlying: array[3, float32].}: Vec3
    color0 {.underlying: array[4, float32].}: Color

let vertices = [
  Vertex(position: vec3(0.0f,  0.5f, 0.5f),  color0: color(1, 0, 0)),
  Vertex(position: vec3(0.5f, -0.5f, 0.5f),  color0: color(0, 1, 0)),
  Vertex(position: vec3(-0.5f, -0.5f, 0.5f), color0: color(0, 0, 1)),
]
const layout = triangle.layout Vertex

var bufferdesc = BufferDesc(data: vertices, label: "triangle-vertices")
delayinit bindings, Bindings:
  bindings.vertex_buffers[0] = gfx.make bufferdesc
delayinit pipeline: gfx.make PipelineDesc(
  shader: gfx.make triangle,
  layout: layout,
  label: "triangle-pipeline"
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
      gfx.draw(0..3)
    gfx.commit()
  cleanup = proc {.cdecl.} =
    gfx.shutdown()
  high_dpi = true
  window_title = "simple"

quit app_desc.start()