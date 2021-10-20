import sokol/[app, gfx, glue, tools, utils]
import chroma, vmath
import cascade

type ColorInput {.packed.} = object
  color {.align: 16.}: Color

importshader "uniform.glsl"

type Vertex = object
  position {.underlying: array[3, float32].}: Vec3

let vertices = [
  Vertex(position: vec3(-0.5, -0.5, 0.5)),
  Vertex(position: vec3(0.5, -0.5, 0.5)),
  Vertex(position: vec3(0, 0.5, 0.5)),
]

var p = ColorInput(color: color(1, 0, 0))

delayinit state: uniform_demo.build(vertices):
  vertex_buffers = [vertices]
  colors[frag_color] = ColorAttachmentAction(action: action_clear, color: color(1, 1, 1))

let app_desc = cascade AppDesc():
  init = proc {.cdecl.} =
    gfx.setup Desc(context: gfx_context())
    doinit()
  frame = proc {.cdecl.} =
    default_pass state.action, width(), height():
      state.pipeline.apply
      state.bindings.apply
      uniform_demo[stage_fs] = p
      gfx.draw(0..3)
    gfx.commit()
  cleanup = proc {.cdecl.} =
    gfx.shutdown()
  high_dpi = true
  window_title = "uniform"

quit app_desc.start()