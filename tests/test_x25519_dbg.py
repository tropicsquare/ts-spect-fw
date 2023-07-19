#!/usr/bin/env python3
import sys
import random as rn

import test_common as tc

import models.random_point_generate_25519_model as rpg
import models.x25519

if __name__ == "__main__":

    ops_cfg = tc.get_ops_config()
    test_name = "x25519_dbg"

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    #scalar = bytes2scalar(rn.randbytes(32))
    scalar = rn.randint(0, 2**256-1)

    DST = rpg.int2bytes(0)
    x, y, z = rpg.point_generate_ed25519(DST, rn.randint(0, 2**256 - 1))

    x = x * models.x25519.inv0(z) % models.x25519.p

    ref = models.x25519.x25519(scalar, x)

    tc.start(cmd_file)
    tc.write_string(cmd_file, scalar, 0x0020)
    tc.write_string(cmd_file, x, 0x0040)
    ctx = tc.run_op(cmd_file, "x25519_dbg", 0x0, 0x1, 64, ops_cfg, test_dir)

    result = rc.read_output(f"{test_dir}/{test_name}_out.hex", 0x1020, 8)

    with open(f"{test_dir}/{test_name}_data.log", mode='w') as dl:
        dl.write("result: " + hex(result) + "\n")
        dl.write("   ref: " + hex(ref) + "\n")

    sys.exit(not(result == ref))
