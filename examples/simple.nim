import sokol/[app, gfx, glue, tools]
import chroma

compileshader staticRead "simple.glsl"

type
  Vertex = object
    position: array[3, float32]
    color0 {.underlying: array[4, float32].}: Color

let vertices = [
  Vertex(position: [0.0f,  0.5f, 0.5f], color0: color(1.0f, 0.0f, 0.0f, 1.0f)),
  Vertex(position: [0.5f, -0.5f, 0.5f], color0: color(0.0f, 1.0f, 0.0f, 1.0f)),
  Vertex(position: [-0.5f, -0.5f, 0.5f], color0: color(0.0f, 0.0f, 1.0f, 1.0f)),
]
const layout = triangle.layout Vertex

var bufferdesc = BufferDesc(data: vertices, label: "triangle-vertices")
var bindings: Bindings
var pipeline: Pipeline
var passAction: PassAction
passAction.colors[0] = ColorAttachmentAction(action: action_clear, color: Color(r: 0.0, g: 0.0, b: 0.0, a: 1.0))

define_app:
  init:
    gfx.setup Desc(context: gfx_context())
    bindings.vertex_buffers[0] = gfx.make bufferdesc
    let shd = gfx.make triangle
    pipeline = gfx.make PipelineDesc(
      shader: shd,
      layout: layout,
      label: "triangle-pipeline"
    )
  frame:
    begin_default_pass passAction, width(), height()
    apply_pipeline pipeline
    apply_bindings bindings
    draw(0, 3, 1)
    end_pass()
    commit()
  cleanup:
    gfx.shutdown()
  app_desc.window_title = "simple"