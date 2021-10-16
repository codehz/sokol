# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import sokol/app

define_app:
  init:
    echo app.isvalid()
    echo app.dimension()
    app.request_quit()
  app_desc.window_title = "my window"