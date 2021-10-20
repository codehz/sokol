import sokol/[app, gfx, glue, tools]
import chroma, vmath

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

var bufferdesc = BufferDesc(data: vertices, label: "instanced-vertices")
var instancedesc = BufferDesc(data: offsets, label: "instanced-instance")
var bindings: Bindings
var pipeline: Pipeline
var passAction: PassAction
passAction.colors[0] = ColorAttachmentAction(action: action_clear, color: color(1, 1, 1))

define_app:
  init:
    gfx.setup Desc(context: gfx_context())
    bindings.vertex_buffers[0] = gfx.make bufferdesc
    bindings.vertex_buffers[1] = gfx.make instancedesc
    let shd = gfx.make triangle
    pipeline = gfx.make PipelineDesc(
      shader: shd,
      layout: layout,
      label: "instanced-pipeline"
    )
  frame:
    default_pass passAction, width(), height():
      pipeline.apply
      bindings.apply
      gfx.draw(whole vertices, offsets.len)
    gfx.commit()
  cleanup:
    gfx.shutdown()
  app_desc.high_dpi = true
  app_desc.window_title = "instanced"