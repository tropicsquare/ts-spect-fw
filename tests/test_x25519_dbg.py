#!/usr/bin/env python3
import sys
import random as rn
import numpy as np
import os
import binascii

import test_common as tc

import models.x25519

if __name__ == "__main__":
    defines_set = tc.get_main_defines()
    if "DEBUG_OPS" not in defines_set:
        tc.print_test_skipped("Debug ops are disabled.")
        sys.exit(0)

    args = tc.parser.parse_args()

    ops_cfg = tc.get_ops_config()
    test_name = "x25519_dbg"
    run_name = test_name

    test_dir = tc.make_test_dir(test_name)

    tc.print_run_name(run_name)

    if args.testvec != "":
        print(f"Reading test vector from {args.testvec}")
        data_dir, rng_list = tc.parse_testvec(args.testvec, tc.rng_luts[test_name])
        priv = tc.str2int(data_dir["priv"], 'little')
        priv_scalar = models.x25519.int2scalar(priv)
        pub = tc.str2int(data_dir["pub"], 'little')
    else:
        seed = tc.set_seed(args)
        rn.seed(seed)
        print("Randomization...")
        print("seed:", seed)
        priv = rn.randint(0, 2**256-1)
        priv_scalar = models.x25519.int2scalar(priv)
        pub = models.x25519.x25519(priv_scalar, 9)
        rng_list = [rn.randint(0, 2**256-1) for i in range(8)]

    cmd_file = tc.get_cmd_file(test_dir)
    tc.set_rng(test_dir, rng_list)
    tc.start(cmd_file)

    R_ref = models.x25519.x25519(priv_scalar, pub)

    tc.write_int256(cmd_file, priv_scalar, 0x0020)
    tc.write_int256(cmd_file, pub, 0x0040)

    ctx = tc.run_op(cmd_file, run_name, 0x0, 0x1, 32, ops_cfg, test_dir)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    if (SPECT_OP_DATA_OUT_SIZE != 32):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        tc.print_failed()
        sys.exit(1)

    R = tc.read_output(test_dir, run_name, 0x1020, SPECT_OP_DATA_OUT_SIZE//4)

    if (not(R_ref == R)):
        print(hex(R_ref))
        print(hex(R))
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm -r {test_dir}")

    sys.exit(0)