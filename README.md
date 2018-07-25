# spdx_licenses [![CircleCI](https://circleci.com/gh/euantorano/spdx_licenses.nim.svg?style=svg)](https://circleci.com/gh/euantorano/spdx_licenses.nim)

A library to retrieve the list of commonly used licenses from [the SPDX License List](https://spdx.org/licenses/).

## Installation

Add to your `.nimble` file:

```nimble
# Dependencies

requires "spdx_licenses >= 1.0.0"
```

Or to install it globally run:

```
nimble install spdx_licenses
```

## Usage

- Retrieving a list of all licenses, as a table keyed by license ID:

```nim
# You can also pass in your own custom `HttpClient` instance if you have one you wish to re-use
let licenses = getLicenseList()

echo "Found licenses: "

for lic in licenses.keys:
  echo "- ", lic
```

- Getting the license text for a specific license by license ID:

```nim
# You can also pass in your own custom `HttpClient` instance if you have one you wish to re-use
let licenseText = getLicenseText("BSD-3-Clause")

echo licenseText
```
