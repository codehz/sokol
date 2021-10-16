import sokol/[app, gfx, glue]

define_app:
  init:
    echo app.isvalid()
    echo app.dimension()
    gfx.setup Desc(context: gfx_context())
    echo gfx.isvalid()
    app.request_quit()
  app_desc.window_title = "my window"