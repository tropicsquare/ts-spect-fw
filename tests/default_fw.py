# -*- coding: utf-8 -*-

import abc
import os
import subprocess

from typing import Tuple

from import_setup import import_setup
import_setup()

from spect_tester.spect_default_fw import (
    SpectFw,
    get_release_version,
    RELEASE_DIR,
)

#############################################################
#   Release Test Helpers
#############################################################
TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]
ROM_VERSION = os.environ["DEFAULT_CONST_ROM"]
VERSION = get_release_version()

class Application(SpectFw):
    s_file = os.path.join(TS_REPO_ROOT, "src", "main.s")
    hex_file = os.path.join(TS_REPO_ROOT, "build", "main.hex32")
    const_rom_file = os.path.join(TS_REPO_ROOT, "build", "spect_const_rom.hex32")

    @classmethod
    def get_release_files(cls) -> Tuple[str, str]:
        constfile = os.path.join(RELEASE_DIR, f"spect_const_rom_code-{ROM_VERSION}.hex32")
        fw_file = os.path.join(RELEASE_DIR, f"spect_app-{VERSION}.hex32")
        return fw_file, constfile