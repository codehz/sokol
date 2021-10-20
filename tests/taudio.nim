import std/random
import sokol/[app, audio, time]

var base: Tick

randomize()

var app_desc: AppDesc

app_desc.init = proc {.cdecl.} =
  assert app.isvalid()
  audio.setup(AudioDesc())
  time.setup()
  base = time.now()

app_desc.frame = proc {.cdecl.} =
  if base.since.sec > 2:
    app.request_quit()
    return
  let count = audio.expect()
  if count == 0: return
  var buf = newSeq[float32](count)
  for val in buf.mitems:
    val = rand(-0.5..0.5)
  discard audio.push buf

app_desc.cleanup = proc {.cdecl.} =
  audio.shutdown()

app_desc.window_title = "my window"

quit app_desc.start()