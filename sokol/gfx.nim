import ./private/backend
# import ./common

{.compile(
  "../upstream/sokol_gfx.h",
  "-x c -DSOKOL_IMPL -DSOKOL_" & sokol_backend
).}