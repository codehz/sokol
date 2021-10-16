# Package

version       = "0.1.0"
author        = "CodeHz"
description   = "Sokol wrapper for nim"
license       = "Zlib"
srcDir        = "."
installDirs   = @["upstream", "sokol", "tools"]

# Dependencies

requires "nim >= 1.4.8"
requires "chroma >= 0.2.5 & < 0.3"

task prepare, "Prepare sokol tools":
  when defined(windows):
    const filename = "sokol-shdc-windows.exe"
  elif defined(macosx):
    const filename = "sokol-shdc-macos"
  elif defined(linux):
    const filename = "sokol-shdc-linux"
  else:
    echo "not support yet"
  exec "curl -Lo " & toExe("tools/sokol-shdc") & " https://github.com/codehz/sokol-tools/releases/download/prebuilt-1/"  & filename

before install:
  if not fileExists(toExe("tools/sokol-shdc")):
    setCommand "prepare"
