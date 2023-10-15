# TS SPECT Firmware

This repository contains the Makefile and associated scripts necessary to build firmware for a specific project. The primary Makefile, named `Makefile`, orchestrates the build process and provides various targets for compiling, releasing, and managing the firmware.

## Documentation

Detailed documentation and resources can be found in the [`doc/`](doc/) folder
of this repository.

## Prerequisites

1. Cloning repository and setting the environment variable `TS_REPO_ROOT` to the repository root.

   ```bash
   # clone the spect firmware repository 
   git clone https://github.com/tropicsquare/ts-spect-fw.git --recurse-submodules

   # set env var TS_REPO_ROOT from root of repository
   cd ts-spect-fw
   export TS_REPO_ROOT=`pwd`
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

## Build firmware
The primary [`makefile`](makefile) orchestrates the build process and provides
various targets for compiling, releasing and managing the firmware.


1. Run the desired build target using `make`. For example, to compile and
release firmware, use:

   ```bash
   make compile && make release_all
   ```

2. For a complete list of targets, consult the makefile or run:
   ```bash
   grep : makefile | awk -F: '/^[^.]/ {print $1;}'
   ```

3. The firmware build artifacts will be generated in the appropriate directories
, such as [`build/`](build/) and [`release/`](release/).
