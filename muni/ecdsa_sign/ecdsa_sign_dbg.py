#!/usr/bin/env python3
import sys
import binascii
import os
import yaml
import random as rn

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]
sys.path.append(TS_REPO_ROOT)

import tests.test_common as tc
import muni.muni_common as mnc

rng_lut = {
    "base_z_rng"    : {"idx": 4, "okzero" : False},
    "point_gen_rng" : {"idx": 5, "okzero" : True},
    "s_rng_1"       : {"idx": 6, "okzero" : True},
    "s_rng_2"       : {"idx": 7, "okzero" : True},
    "t_rng"         : {"idx": 8, "okzero" : False}
}

if __name__ == "__main__":
    run_name = "ecdsa_sign_dbg"
    tc.print_run_name(run_name)
    cmd_cfg, data_cfg = mnc.get_cfg(run_name)

    test_dir, cmd_file = mnc.run_init()

    tc.start(cmd_file)

    mnc.write_input(cmd_file, cmd_cfg, data_cfg)

    rng_list = mnc.set_rng_list(data_cfg, rng_lut)

    tc.set_rng(test_dir, rng_list)

    mnc.run(cmd_file, test_dir, cmd_cfg)

    res_r_addr = mnc.get_address("r", cmd_cfg, "output")
    res_s_addr = mnc.get_address("s", cmd_cfg, "output")

    res_r_int = tc.read_output(test_dir, run_name, res_r_addr, 8)
    res_s_int = tc.read_output(test_dir, run_name, res_s_addr, 8)

    print("Signature r: ", hex(res_r_int))
    print("Signature s: ", hex(res_s_int))

    sys.exit(0)