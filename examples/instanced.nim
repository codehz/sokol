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

delayinit state: instanced.build(vertices, offsets):
  vertex_buffers     = [vertices, offsets]
  colors[frag_color] = ColorAttachmentAction(action: action_clear, color: color(1, 1, 1))

let app_desc = cascade AppDesc():
  init = proc {.cdecl.} =
    gfx.setup Desc(context: gfx_context())
    doinit()
  frame = proc {.cdecl.} =
    default_pass state.action, width(), height():
      state.pipeline.apply
      state.bindings.apply
      gfx.draw(whole vertices, offsets.len)
    gfx.commit()
  cleanup = proc {.cdecl.} =
    gfx.shutdown()
  high_dpi = true
  window_title = "instanced"

quit app_desc.start()