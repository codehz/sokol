Sokol wrapper for nim
=====================

example code:
```nim
import sokol/[app, gfx, glue, tools, utils]
import chroma, vmath

# compile shader on the fly!
importshader "instanced.glsl" # see examples folder

# build pipeline layout based on type declration
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

define_app:
  init:
    gfx.setup Desc(context: gfx_context())
    doinit()
  frame:
    default_pass state.action, width(), height():
      state.pipeline.apply
      state.bindings.apply
      gfx.draw(whole vertices, offsets.len)
    gfx.commit()
  cleanup:
    gfx.shutdown()
  app_desc.high_dpi = true
  app_desc.window_title = "instanced"
```