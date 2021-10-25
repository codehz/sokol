import ./common

const saudio_ring_max_slots {.intdefine.} = 1024
{.compile(
  "../upstream/sokol_audio.h",
  "-x c -DSOKOL_IMPL -DSAUDIO_RING_MAX_SLOTS=" & $saudio_ring_max_slots
).}

when not defined(sokol_manuallink):
  when defined(windows):
    {.passL: "-lole32".}
  elif defined(linux):
    when defined(android):
      {.passL: "-lOpenSLES".}
    else:
      {.passL: "-lasound".}
  else:
    {.warning: "You need manually link external libraries".}

type
  AudioDesc* = object
    sample_rate*, num_channels*, buffer_frames*, packet_frames*, num_packets*: int32
    stream_cb*: proc (buffer: ptr UncheckedArray[float32], num_frames, num_channels: int32) {.cdecl.}
    stream_userdata_cb*: proc (buffer: ptr UncheckedArray[float32], num_frames, num_channels: int32, user_data: pointer) {.cdecl.}
    user_data*: pointer

{.push importc: "saudio_$1", cdecl.}
proc setup*(desc: ConstView[AudioDesc]) {.fixConstView.}
proc shutdown*
proc isvalid*: bool
proc userdata*: pointer
proc query_desc*: AudioDesc
proc sample_rate*: int32
proc buffer_frames*: int32
proc channels*: int32
proc expect*: int32
proc push(frames: ptr UncheckedArray[float32], num_frames: int32): int32
{.pop.}

proc push*(frames: var openArray[float32]): int32 =
  push(cast[ptr UncheckedArray[float32]](addr frames), int32 frames.len)