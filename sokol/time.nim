
{.compile("../upstream/sokol_time.h", "-x c -DSOKOL_IMPL").}

type Tick = distinct uint64

proc `$`*(tick: Tick): string = "tick(" & $uint64(tick) & ")"

proc `-`*(a, b: Tick): Tick {.importc: "stm_diff", cdecl.}

{.push importc: "stm_$1", cdecl.}
proc setup*
proc now*: Tick
proc since*(start: Tick): Tick
proc laptime*(last: var Tick): Tick
proc round_to_common_refresh_rate*(duration: Tick): Tick

proc sec*(ticks: Tick): float64
proc ms*(ticks: Tick): float64
proc us*(ticks: Tick): float64
proc ns*(ticks: Tick): float64
{.pop.}