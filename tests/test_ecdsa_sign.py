#!/usr/bin/env python3
import sys
import random as rn

import test_common as tc
import models.p256 as p256

if __name__ == "__main__":

    seed = rn.randint(0, 2**32-1)
    rn.seed(seed)
    print("seed:", seed)

    ops_cfg = tc.get_ops_config()
    test_name = "ecdsa_sign"
    run_name = test_name

    tc.print_run_name(run_name)

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    rng = [rn.randint(0, 2**256-1) for i in range(16)]
    tc.set_rng(test_dir, rng)

    # Generate test vector
    d, w, _, _ = p256.key_gen(int.to_bytes(rn.randint(0, 2**256-1), 32, 'big'))

    sch = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    scn = int.to_bytes(rn.randint(0, 2**32-1), 4, 'little')

    z = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    #print()
    #print("d:   ", hex(d))
    #print("w:   ", w.hex())
    #print("sch: ", sch.hex())
    #print("scn: ", scn.hex())
    #print("z:   ", z.hex())

    r_ref, s_ref = p256.sign(d, w, sch, scn, z)
    #print()
    #print("r_ref:", hex(r_ref))
    #print("s_ref:", hex(s_ref))

    # Write Keys and inputs
    slot = rn.randint(0, 7)

    wint = int.from_bytes(w, 'big')
    tc.set_key(cmd_file, key=d,    ktype=0x04, slot=(slot<<1), offset=0)
    tc.set_key(cmd_file, key=wint, ktype=0x04, slot=(slot<<1), offset=8)

    insrc = 0x4
    outsrc = 0x5

    tc.write_bytes(cmd_file, z, (insrc<<12) + 0x10)
    tc.write_bytes(cmd_file, sch, 0x00A0)
    tc.write_bytes(cmd_file, scn, 0x00C0)

    input_word = (slot << 8) + tc.find_in_list("ecdsa_sign", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    # set breakpoints to dump GPR values
    #break_s = tc.dump_gpr_on(cmd_file, "ecdsa_sign_mask_k", [27, 26])

    # Run Op
    ctx = tc.run_op(cmd_file, "ecdsa_sign", insrc, outsrc, 0, ops_cfg, test_dir, run_name)

    # Read result
    l3_result = tc.read_output(test_dir, run_name, outsrc<<12, 1)
    l3_result &= 0xFF

    r = tc.read_output(test_dir, run_name, (outsrc<<12) + 0x10, 8)
    s = tc.read_output(test_dir, run_name, (outsrc<<12) + 0x30, 8)

    #print("r    :", hex(r))
    #print("s    :", hex(s))

    if not(r == r_ref and s == s_ref):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()
    sys.exit(0)