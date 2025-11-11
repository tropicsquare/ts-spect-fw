# TS SPECT Application Firmware

This repository contains the Makefile and associated scripts necessary to build firmware for a specific project.

The primary Makefile, named `Makefile`, orchestrates the build process and provides various targets for compiling,
releasing, and managing the firmware.

## Licensing

See [LICENSE](LICENSE) file

---

## Table of Contents

[Repository structure ](#repository-structure-)

[Documentation](#doc-)

[Prerequisites ](#prerequisites-)

[Build firmware ](#build-firmware-)

[Release ](#release-)

[Test/Simulate firmware ](#testsimulate-firmware-)

## Repository structure <a name="repostruct"></a>

- [`doc`](doc/) : firmware and algorithms documentation
- [`modules`](modules/) : submodules used by this project:
   - [`ts-spect-sdk`](modules/ts-spect-sdk/) : SPECT SDK for firmware development
- [`scripts`](scripts/) : support scripts
- [`src`](src/) : firmware source files
- [`tests`](tests/) : python tests

## Documentation <a name="doc"></a>

[**SPECT Firmware API**](doc/spect_fw_api/spect_fw_api.pdf)

[**Misc Doc**](doc/README.md)

## Prerequisites <a name="prereq"></a>
---
1. Cloning the repository

   ```bash
   # clone the spect application firmware repository
   git clone https://github.com/tropicsquare/ts-spect-fw.git --recurse-submodules
   cd ts-spect-fw
   ```

2. Setting necessary environment variables

   ```bash
   # Set repository root
   export TS_REPO_ROOT=`pwd`

   # Set default revision of Const ROM
   export DEFAULT_CONST_ROM="revA"
   ```

2. Ensure you have the `spect_compiler` and `spect_iss` binaries in the environment path. These are part
of the [`ts-spect-compiler`](https://github.com/tropicsquare/ts-spect-compiler)
repository.

   ```bash
   spect_compiler --help
   spect_iss --help
   ```

3. Ensure that Python and certain Python packages are installed on your system or python environment:
   ```bash
   pip install -r requirements.txt
   ```

## Build firmware <a name="fwbuild"></a>
---
The primary [`Makefile`](Makefile) orchestrates the build process and provides
various targets for compiling, releasing and managing the firmware. Run the desired build target using `make`.

1. To restore the state of the repository, use:

   ```bash
   make clear
   ```

2. To compile application firmware to `build` directory, use:

   ```bash
   make compile
   ```

3. To set a Const ROM version for the build, set the `ROM_VERSION` variable:

   ```bash
   make compile ROM_VERSION=<version>
   ```
   See available versions in [ts-spect-sdk](modules/ts-spect-sdk/data)

## Release <a name="release"></a>
---
Release application firmware with

```bash
make release
```

This creates `release` directory with following structure.

`version` = `git describe --dirty`

| Name | Type | Description |
| - | - | - |
| `spect_app_<version>.hex32` | File | Compiled application firmware |
| `spect_app_<version>.hex` | Soft link | Link to `spect_app_<version>.hex32` |
| `spect_const_rom_code_<version>.hex32` | File | Constants ROM code |
| `spect_const_rom_code_<version>.hex` | Soft link | Link to `spect_const_rom_code_<version>.hex32` |
| `compile.log` | File | Compilation log files |
| `spect_ops_constants.h` | File | C header file with SPECT API defines |
| `dump` | Directory |  Program and symbols dump files |

## Test/Simulate firmware <a name="fwtestsim"></a>
---
Python scrips for firmware testing and simulation are located in [`tests`](tests) directory. The tests use `models` and `spect_tester` from `ts-spect-sdk` submodule.
