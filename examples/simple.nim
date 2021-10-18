import sokol/[app, gfx, glue, tools]
import print
import macros

expandMacros:
  importshader "examples/simple.glsl"

print triangle

define_app:
  init:
    gfx.setup Desc(context: gfx_context())
  cleanup:
    gfx.shutdown()
  app_desc.window_title = "simple"