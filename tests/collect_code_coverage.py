#!/usr/bin/env python3

import glob
import os
import numpy as np

from default_fw import Application

from import_setup import import_setup
import_setup()

from spect_tester.spect_tester import SpectTester

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]

if __name__ == "__main__":

    exec_infos = glob.glob(f"{SpectTester.TESTER_DIR}/*/*/exec_info")

    with open(Application.hex_file, 'r') as fw:
        fw_size = len(fw.readlines())

    coverage = np.zeros(shape=(fw_size), dtype=np.uint32)

    for exec_info in exec_infos:
        # Avoid counting Bootloader
        if "bootloader" in exec_info:
            continue

        with open(exec_info, 'r') as f:
            for line in f:
                line_split = line.split(':')
                addr = int(line_split[0], 16)
                exec_num = int(line_split[1], 16)

                coverage[(addr-0x8000)//4] += exec_num

    num_zeros = np.count_nonzero(coverage == 0)

    print(f"Coverage: {100*(fw_size-num_zeros)/fw_size :0.2f} %")
    print(f"Number of not executed instructions: {num_zeros}")

    with open(f"{TS_REPO_ROOT}/build/program_dump.s", 'r') as pg:
        pg_lines = pg.readlines()

        for i in range(fw_size):
            if coverage[i] == 0:
                nl = pg_lines[i].strip()
                nl += " <<<<<<<<<<<<<<<<<<<<<\n"
                pg_lines[i] = nl

    with open(f"{TS_REPO_ROOT}/tests/program_dump_coverage.s", 'w') as pg:
        pg.writelines(pg_lines)
