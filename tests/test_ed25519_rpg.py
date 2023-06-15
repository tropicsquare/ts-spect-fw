#!/usr/bin/env python3
import random as rn
import sys
import test_common as tc
import models.random_point_generate_25519_model as rpg

if __name__ == "__main__":
    ops_cfg = tc.get_ops_config()
    test_name = "ed25519_rpg"

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    rng = [rn.randint(0, 2**256 - 1) for i in range(4)]
    DST_ID = rn.randint(0, 255)
    DST_INT = 0x54535F53504543545F445354000000000000000000000000000000000000+DST_ID
    DST = rpg.int2bytes(DST_INT)
    x_ref, y_ref, z_ref = rpg.point_generate_ed25519(DST, rng[0])

    if not rpg.is_on_ed25519(x_ref, y_ref, z_ref):
        print("Model failed.")
        sys.exit(1)

    tc.set_rng(test_dir, rng)

    tc.start(cmd_file)

    tc.write_int32(cmd_file, DST_ID, 0x0020)

    ctx = tc.run_op(cmd_file, "ed25519_rpg", ops_cfg, test_dir)

    x = tc.read_output(f"{test_dir}/{test_name}_out.hex", 0x1000, 8)
    y = tc.read_output(f"{test_dir}/{test_name}_out.hex", 0x1020, 8)
    z = tc.read_output(f"{test_dir}/{test_name}_out.hex", 0x1040, 8)

    with open(f"{test_dir}/{test_name}_data.log", mode='w') as dl:
        dl.write("rng: " + hex(rng[0]) + "\n")
        dl.write("DST: " + hex(DST_INT) + "\n")
        dl.write("\n")
        dl.write("x_ref: " + hex(x_ref) + "\n")
        dl.write("x    : " + hex(x) + "\n")
        dl.write("\n")
        dl.write("y_ref: " + hex(y_ref) + "\n")
        dl.write("y    : " + hex(y) + "\n")
        dl.write("\n")
        dl.write("z_ref: " + hex(z_ref) + "\n")
        dl.write("z    : " + hex(z) + "\n")

    sys.exit(not( x == x_ref and y == y_ref and z == z_ref ))
