# TS SPECT Application Firmware

The primary function of the SPECT Application is to handle all Elliptic Curve Cryptography related
functionality of the TROPIC01 chip.

We have one FW for the main RISCV32 CPU and a second for the SPECT coprocessor. This repository
contains all code and tests for SPECT Application firmware. 

## Licensing

See [LICENSE](LICENSE) file.

---

## Table of Contents

[Repository Structure ](#repository-structure)

[Prerequisites ](#prerequisites)

[Build ](#build)

[Release ](#release)

[Tests and FWFE ](#tests-and-fwfe)

## Repository Structure

```
├─ spect_ops_config.yml    # Configuration of SPECT Ops
├─ src                     # Source files
├─ tests                   # Python scripts for verification
├─ doc                     # API documentation and support markdowns
├─ scripts                 # Support scripts
├─ modules                 # Repository submodules
│  └─ ts-spect-sdk         # SPECT SDK (test env. + Const ROM content)
├─ build                   # Automatically created build destination
├─ release                 # Automatically created release destination
├─ LICENSE                 # LICENSE file
├─ CHANGELOG.md            # CHANGELOG file
└─ Makefile                # Makefile for building and release
```

## Prerequisites
---
1. Cloning the repository

   ```bash
   # clone the SPECT FW repository
   git clone https://github.com/tropicsquare/ts-spect-fw.git --recurse-submodules
   cd ts-spect-fw
   ```

2. Setting necessary environment variables

   ```bash
   # Set repository root
   export TS_REPO_ROOT=`pwd`

   # Set default revision of Const ROM <revA, revB, devel>
   export DEFAULT_CONST_ROM="revB"
   ```

> [!TIP]
> See available versions in [ts-spect-sdk](modules/ts-spect-sdk/data)

3. Ensure you have the `spect_compiler` and `spect_iss` binaries in the environment path. These are part
of the [`ts-spect-compiler`](https://github.com/tropicsquare/ts-spect-compiler)
repository.

   ```bash
   spect_compiler --help
   spect_iss --help
   ```

4. Ensure your version of `spect_compiler` and `spect_iss` is >= v0.10:

    ```bash
    spect_compiler --version
    spect_iss --version
    ```

## Build
---
The primary [`Makefile`](Makefile) orchestrates the build process and provides
various targets for compiling, releasing and managing the firmware. Run the desired build target using `make`.

1. To restore the state of the repository, use:

   ```bash
   make clear
   ```

2. To compile firmware to `build` directory, use:

   ```bash
   make compile
   ```

3. To set a Const ROM version specifically for this build, set the `ROM_VERSION` variable:

   ```bash
   make compile ROM_VERSION=<version>
   ```

## Release
---
Release application firmware with

   ```bash
   make clear
   make release
   ```

This creates `release` directory with the following structure:

- `FW_VERSION` = `git describe --dirty`
- `ROM_VERSION` = `$DEFAULT_CONST_ROM` by default. Can be changed with the `ROM_VERSION` variable when doing the release.

| Name | Type | Description |
| - | - | - |
| `spect_app-<FW_VERSION>.hex32` | File | Compiled firmware |
| `spect_app-<FW_VERSION>.hex` | Soft link | Link to `spect_app-<FW_VERSION>.hex32` |
| `spect_const_rom_code-<ROM_VERSION>.hex32` | File | Constants ROM code |
| `spect_const_rom_code-<ROM_VERSION>.hex` | Soft link | Link to `spect_const_rom_code-<ROM_VERSION>.hex32` |
| `compile.log` | File | Compilation log |
| `spect_ops_constants.h` | File | C header file with SPECT API defines |
| `dump` | Directory | Program and symbols dump files |

## Tests and FWFE
---
Python scripts for firmware testing and simulation are located in [`tests`](tests) directory. The tests use `models` and `spect_tester` from `ts-spect-sdk` submodule.

To be able to run the tests, make sure you have the repository set up properly as described in [Prerequisites ](#prerequisites-). To run a single test, ensure you have the FW you want to test built in the `build` directory.

### Run regression

```bash
cd tests
./regression.sh
```

### Run regression on release target

```bash
cd tests
make -C .. release
./regression_release.sh
```

### Test Code Coverage

After you run the tests, you can collect the test code coverage:

```bash
./collect_code_coverage.py
```

This outputs the coverage in percent and number of not executed instructions. It also creates a `program_dump_coverage.s` file, with the not executed instructions marked with `>>>`.

### FWFE

> [!NOTE]
> Currently, there is no Firmware Fault Emulation test.
