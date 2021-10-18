import sokol/[app, gfx, glue, tools]
import print

compileshader staticRead "simple.glsl"

print triangle

var vertices = [
  0.0f,  0.5f, 0.5f, 1.0f, 0.0f, 0.0f, 1.0f,
  0.5f, -0.5f, 0.5f, 0.0f, 1.0f, 0.0f, 1.0f,
  -0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f, 1.0f
]

let bufferdesc = BufferDesc(data: vertices, label: "triangle-vertices")
var bindings: Bindings

print bufferdesc

define_app:
  init:
    gfx.setup Desc(context: gfx_context())
    bindings.vertex_buffers[0] = gfx.make bufferdesc
    let shd = gfx.make triangle
    echo int shd
  cleanup:
    gfx.shutdown()
  app_desc.window_title = "simple"