import sokol/[app, gfx, glue]

define_app:
  init:
    echo is_app_valid()
    echo dimension()
    setup Desc(context: gfx_context())
    echo is_gfx_valid()
    request_quit()
  app.window_title = "my window"