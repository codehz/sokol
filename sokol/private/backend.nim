when not defined(sokol_backend):
  when defined(windows):
    const sokol_backend* = "D3D11"
  else:
    const sokol_backend* = "GLCORE33"

when not defined(sokol_manuallink):
  when defined(windows):
    {.passL: "-lkernel32 -luser32 -lshell32".}
    when sokol_backend == "D3D11":
      {.passL: "-lgdi32 -ld3d11 -ldxgi".}
    elif sokol_backend == "GLCORE33":
      {.passL: "-lgdi32".}
    else:
      {.error: "not supported".}
  elif defined(linux):
    when defined(android):
      {.error: "Android platform is not supported".}
    else:
      {.passL: "-lX11 -lXi -lXcursor -lGL -ldl -lpthread -lm".}
  else:
    {.warning: "You need manually link external libraries".}