#!/usr/bin/env python3
import sys
import random as rn

import test_common as tc

import models.random_point_generate_25519_model as rpg
import models.x25519

if __name__ == "__main__":

    
    ops_cfg = tc.get_ops_config()
    test_name = "x25519_kpair_gen"

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    #scalar = models.x25519.bytes2scalar(rn.randbytes(32))
    #scalar = rn.randint(0, 2**256-1)
    rng = [
        0x1111,
        0x2222,
        0x3333,
        0x4444,
        0x5555,
        0x6666,
        0x7777,
        0x8888
    ]

    tc.set_rng(test_dir, rng)

    ref = models.x25519.x25519(models.x25519.int2scalar(rng[0]), 9)

    ctx = tc.run_op(cmd_file, "x25519_kpair_gen", 0x0, 0x1, 0x0000, ops_cfg, test_dir)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, test_name)

    print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
    print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)

    x = tc.read_output(f"{test_dir}/{test_name}_out.hex", 0x1020, SPECT_OP_DATA_OUT_SIZE//4)

    print("ref:", hex(ref))
    print("res:", hex(x))

    db_x = tc.read_output(f"{test_dir}/{test_name}_out.hex", 0x1040, 8)
    db_z = tc.read_output(f"{test_dir}/{test_name}_out.hex", 0x1060, 8)
    db_y = tc.read_output(f"{test_dir}/{test_name}_out.hex", 0x1080, 8)

    print(hex(db_x))
    print(hex(db_z))
    print(hex(db_y))


    sys.exit(not(ref == x))