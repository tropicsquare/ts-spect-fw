#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc
import models.p256 as p256

if __name__ == "__main__":

    seed = rn.randint(0, 2**32-1)
    rn.seed(seed)
    print("seed:", seed)

    ops_cfg = tc.get_ops_config()
    test_name = "ecdsa_sign_dbg"
    run_name = test_name

    tc.print_run_name(run_name)

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    rng = [rn.randint(0, 2**256-1) for i in range(16)]
    tc.set_rng(test_dir, rng)

    # Generate test vector
    d, w, Ax, Ay = p256.key_gen(int.to_bytes(rn.randint(0, 2**256-1), 32, 'big'))

    sch = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    scn = int.to_bytes(rn.randint(0, 2**32-1), 4, 'little')

    z = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    #print()
    #print("d:   ", hex(d))
    #print("w:   ", w.hex())
    #print("sch: ", sch.hex())
    #print("scn: ", scn.hex())
    #print("z:   ", z.hex())
    #print("Ax:  ", hex(Ax))
    #print("Ay:  ", hex(Ay))

    r_ref, s_ref = p256.sign(d, w, sch, scn, z)

    signature_ref = r_ref.to_bytes(32, 'big') + s_ref.to_bytes(32, 'big')
    #print()
    #print("r_ref:", hex(r_ref))
    #print("s_ref:", hex(s_ref))

    # Write Keys and inputs
    slot = rn.randint(0, 7)

    wint = int.from_bytes(w, 'big')
    tc.write_int256(cmd_file, d, 0x0040)
    tc.write_int256(cmd_file, wint, 0x0060)
    tc.write_int256(cmd_file, Ax, 0x0160)
    tc.write_int256(cmd_file, Ay, 0x0180)

    insrc = 0x0
    outsrc = 0x1

    tc.write_bytes(cmd_file, z, (insrc<<12) + 0x10)
    tc.write_bytes(cmd_file, sch, 0x00A0)
    tc.write_bytes(cmd_file, scn, 0x00C0)

    input_word = (slot << 8) + tc.find_in_list("ecdsa_sign", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    # Run Op
    ctx = tc.run_op(cmd_file, "ecdsa_sign_dbg", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name, main="src/main_debug.s")

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(0)

    # Read result
    l3_result = tc.read_output(test_dir, run_name, outsrc<<12, 1)
    l3_result &= 0xFF

    signature = tc.read_output(test_dir, run_name, (outsrc<<12) + 0x10, 16, string=True)

    #print(signature_ref.hex())
    #print(signature.hex())

    if not(signature_ref == signature):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm -r {test_dir}")

    sys.exit(0), 