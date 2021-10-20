import sokol/[app, gfx, glue]

var app_desc: AppDesc
app_desc.init = proc {.cdecl.} =
  echo app.isvalid()
  echo app.dimension()
  gfx.setup Desc(context: gfx_context())
  echo gfx.isvalid()
  app.request_quit()
app_desc.cleanup = proc {.cdecl.} =
  gfx.shutdown()
app_desc.window_title = "my window"

quit app_desc.start()