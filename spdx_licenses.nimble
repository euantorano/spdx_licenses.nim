# Package

version       = "1.0.0"
author        = "Euan T"
description   = "A library to retrieve the list of commonly used licenses from the SPDX License List."
license       = "BSD-3-Clause"
srcDir        = "src"

# Dependencies

requires "nim >= 0.18.0"

task docs, "Create documentation":
  exec "nim doc --index:on -o:docs/spdx_licenses.html src/spdx_licenses.nim"

task test, "Run the tests":
  withDir "tests":
    exec "nim c -r main"
