#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc
import models.p256 as p256

if __name__ == "__main__":

    args = tc.parser.parse_args()
    seed = tc.set_seed(args)
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
    tc.set_key(cmd_file, key=d,          ktype=0x04, slot=(slot<<1),   offset=0)
    tc.set_key(cmd_file, key=wint,       ktype=0x04, slot=(slot<<1),   offset=8)
    tc.set_key(cmd_file, key=tc.P256_ID, ktype=0x04, slot=(slot<<1)+1, offset=0)
    tc.set_key(cmd_file, key=Ax,         ktype=0x04, slot=(slot<<1)+1, offset=8)
    tc.set_key(cmd_file, key=Ay,         ktype=0x04, slot=(slot<<1)+1, offset=16)

    insrc = tc.insrc_arr[rn.randint(0,1)]
    outsrc = tc.outsrc_arr[rn.randint(0,1)]

    tc.write_bytes(cmd_file, z, (insrc<<12) + 0x10)
    tc.write_bytes(cmd_file, sch, 0x00A0)
    tc.write_bytes(cmd_file, scn, 0x00C0)

    input_word = (slot << 8) + tc.find_in_list("ecdsa_sign", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    # set breakpoints to dump GPR values
    break_s = tc.dump_gpr_on(cmd_file, "bp_ecdsa_sign_ver_after_u1G", [9, 10, 11])
    break_s += tc.dump_gpr_on(cmd_file, "bp_ecdsa_sign_ver_after_u2A", [9, 10, 11])

    # Run Op
    ctx = tc.run_op(cmd_file, "ecdsa_sign", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    sing_size = (SPECT_OP_DATA_OUT_SIZE - 16) // 4

    # Read result
    l3_result = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result &= 0xFF

    signature = tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, sing_size, string=True)

    #print(signature_ref.hex())
    #print(signature.hex())

    if not(signature_ref == signature):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm -r {test_dir}")

    sys.exit(0)