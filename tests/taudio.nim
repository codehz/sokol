import std/random
import sokol/[app, audio, time]

var base: Tick

randomize()

define_app:
  init:
    assert app.isvalid()
    audio.setup(AudioDesc())
    time.setup()
    base = time.now()
  frame:
    if base.since.sec > 2:
      app.request_quit()
      return
    let count = audio.expect()
    if count == 0: return
    var buf = newSeq[float32](count)
    for val in buf.mitems:
      val = rand(-0.5..0.5)
    discard audio.push buf
  app_desc.window_title = "my window"