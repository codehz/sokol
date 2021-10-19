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
    const filename = "win32/sokol-shdc.exe"
  elif defined(macosx):
    const filename = "osx/sokol-shdc"
  elif defined(linux):
    const filename = "linux/sokol-shdc"
  else:
    echo "not support yet"
  const HASH = "QmTtmWPhqTB2RWMjqhavLpTJJVbmbiQY2yEfw9MtMf6mbZ"
  exec "curl -Lo " & toExe("tools/sokol-shdc") & " https://ipfs.io/ipfs/" & HASH & "/"  & filename
  when not defined(windows):
    exec "chmod +x tools/sokol-shdc"

task prepare, "Prepare environment":
  if not fileExists(toExe("tools/sokol-shdc")):
    exec "nimble download"

before install:
  exec "nimble prepare"
