import sokol/[app, gfx, glue, tools]

static:
  echo compile_shader"""
@vs vs
in vec4 position;
in vec4 color0;

out vec4 color;

void main() {
    gl_Position = position;
    color = color0;
}
@end

@fs fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}
@end

@program triangle vs fs
"""

define_app:
  init:
    gfx.setup Desc(context: gfx_context())
  cleanup:
    gfx.shutdown()
  app_desc.window_title = "simple"