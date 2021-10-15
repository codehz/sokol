# Package

version       = "0.1.0"
author        = "CodeHz"
description   = "Sokol wrapper for nim"
license       = "Zlib"
srcDir        = "."
installDirs   = @["upstream", "sokol"]

# Dependencies

requires "nim >= 1.4.8"
requires "chroma >= 0.2.5 & < 0.3"