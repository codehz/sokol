import sokol/[app, gfx, glue, tools]
import chroma, vmath

compileshader staticRead "simple.glsl"

type
  Vertex = object
    position {.underlying: array[3, float32].}: Vec3
    color0 {.underlying: array[4, float32].}: Color

let vertices = [
  Vertex(position: vec3(0.0f,  0.5f, 0.5f),  color0: color(1, 0, 0)),
  Vertex(position: vec3(0.5f, -0.5f, 0.5f),  color0: color(0, 1, 0)),
  Vertex(position: vec3(-0.5f, -0.5f, 0.5f), color0: color(0, 0, 1)),
]
const layout = triangle.layout Vertex

var bufferdesc = BufferDesc(data: vertices, label: "triangle-vertices")
var bindings: Bindings
var pipeline: Pipeline
var passAction: PassAction
passAction.colors[0] = ColorAttachmentAction(action: action_clear, color: color(1, 1, 1))

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
  app_desc.high_dpi = true
  app_desc.window_title = "simple"