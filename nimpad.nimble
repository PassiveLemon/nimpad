# Package
packageName = "nimpad"
version = "0.3.1"
author = "PassiveLemon"
description = "A Nim based client for a DIY macropad"
license = "GPL-3.0-only"
srcDir = "src"
bin = @["nimpad"]

# Dependencies
requires "nim >= 2.2.0"
requires "serial >= 1.2.0"
requires "https://github.com/PassiveLemon/libevdev-nim.git#4d9b3581df1b95ffc400ae965958039e0687f1d0" # Libevdev

