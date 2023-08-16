#!/usr/bin/env python3
import sys
import random as rn
import numpy as np
import os

import test_common as tc

import models.x25519

if __name__ == "__main__":

    seed = rn.randint(0, 2**32-1)
    rn.seed(seed)
    print("seed:", seed)

    ops_cfg = tc.get_ops_config()
    test_name = "x25519_dbg"
    run_name = test_name

    test_dir = tc.make_test_dir(test_name)

    priv = rn.randint(0, 2**256-1)
    priv_scalar = models.x25519.int2scalar(priv)
    pub = models.x25519.x25519(priv_scalar, 9)

    tc.print_run_name(run_name)
    cmd_file = tc.get_cmd_file(test_dir)
    rng = [rn.randint(0, 2**256-1) for i in range(8)]
    tc.set_rng(test_dir, rng)
    tc.start(cmd_file)

    R_ref = models.x25519.x25519(priv_scalar, pub)

    tc.write_int256(cmd_file, priv_scalar, 0x0020)
    tc.write_int256(cmd_file, pub, 0x0040)

    ctx = tc.run_op(cmd_file, run_name, 0x0, 0x1, 32, ops_cfg, test_dir, main="src/main_debug.s", tag="Debug")

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    R = tc.read_output(test_dir, run_name, 0x1020, SPECT_OP_DATA_OUT_SIZE//4)

    if (not(R_ref == R)):
        print(hex(R_ref))
        print(hex(R))
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

    sys.exit(0)