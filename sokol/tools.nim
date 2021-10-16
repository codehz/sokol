import ./private/backend

when not defined(shdcExec):
  when defined(windows):
    const shdcExec* = "cmd /c ..\\tools\\sokol-shdc.exe"
  else:
    const shdcExec* = "../tools/sokol-shdc"

when not defined(shaderTarget):
  when sokol_backend == "D3D11":
    const shaderTarget = "hlsl5"
  elif sokol_backend == "GLCORE33" or sokol_backend == "GLES2" or sokol_backend == "GLES3":
    const shaderTarget = "glsl330:glsl100:glsl300es"
  elif sokol_backend == "METAL":
    when defined (macosx):
      const shaderTarget = "metal_macos"
    else:
      const shaderTarget = "metal_ios"
  elif sokol_backend == "WGPU":
    const shaderTarget = "wgpu"
  else:
    {.error: "Cannot detect shader language".}

proc compile_shader*(content: static string): string {.compileTime.} =
  let (output, code) = gorgeEx(shdcExec & " -i @ -l " & shaderTarget & " -o @ -f metadata -b", content, "OwO")
  doAssert code == 0, "Failed to compile shader: " & output
  output
