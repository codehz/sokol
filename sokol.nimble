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

task download, "Download sokol shdc":
  when defined(windows):
    const filename = "sokol-shdc-win32.exe"
  elif defined(macosx):
    const filename = "sokol-shdc-osx"
  elif defined(linux):
    const filename = "sokol-shdc-linux"
  else:
    echo "not support yet"
  const TAG = "build-6f6ac9bf1c8963fba296841c5977a8b47bb09ce7"
  exec "curl -Lo " & toExe("tools/sokol-shdc") & " https://github.com/codehz/sokol-tools/releases/download/" & TAG & "/"  & filename
  when not defined(windows):
    exec "chmod +x tools/sokol-shdc"

task prepare, "Prepare environment":
  if not fileExists(toExe("tools/sokol-shdc")):
    exec "nimble download"

before install:
  exec "nimble prepare"
