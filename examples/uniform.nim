import sokol/[app, gfx, glue, tools]
import chroma, vmath

importshader "uniform.glsl"

type Vertex = object
  position {.underlying: array[3, float32].}: Vec3

let vertices = [
  Vertex(position: vec3(-0.5, -0.5, 0.5)),
  Vertex(position: vec3(0.5, -0.5, 0.5)),
  Vertex(position: vec3(0, 0.5, 0.5)),
]

var p = ColorInput(color: [1f32, 0, 0])

let layout = uniform_demo.layout Vertex
var bufferdesc = BufferDesc(data: vertices, label: "triangle-vertices")
var bindings: Bindings
var pipeline: Pipeline
var passAction: PassAction
passAction.colors[0] = ColorAttachmentAction(action: action_clear, color: color(1, 1, 1))

define_app:
  init:
    gfx.setup Desc(context: gfx_context())
    bindings.vertex_buffers[0] = gfx.make bufferdesc
    let shd = gfx.make uniform_demo
    pipeline = gfx.make PipelineDesc(
      shader: shd,
      layout: layout,
      label: "triangle-pipeline"
    )
  frame:
    default_pass passAction, width(), height():
      pipeline.apply
      bindings.apply
      let uf: RangePtr = p
      stage_fs.apply_uniforms(0, uf)
      gfx.draw(0, 3, 1)
    gfx.commit()
  cleanup:
    gfx.shutdown()
  app_desc.high_dpi = true
  app_desc.window_title = "simple"