#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc

if __name__ == "__main__":

    seed = rn.randint(0, 2**32-1)
    rn.seed(seed)
    print("seed:", seed)
    
    ops_cfg = tc.get_ops_config()
    test_name = "ecc_key_read"

    test_dir = tc.make_test_dir(test_name)

    ret = 0

# ===================================================================================
#   Curve = Ed25519
# ===================================================================================
    cmd_file = tc.get_cmd_file(test_dir)

    A_ref = rn.randint(1,2**256 - 1)
    curve_ref = 0x02
    origin_ref = 0x60

    slot = rn.randint(0, 127)
    pubkey_slot = (slot << 1)+1

    run_name = test_name + "_ed25519_" + f"{slot}"

    tc.print_run_name(run_name)

    tc.set_key(cmd_file, curve_ref + (origin_ref << 8), ktype=0x4, slot=pubkey_slot, offset=0)
    tc.set_key(cmd_file, A_ref, ktype=0x4, slot=pubkey_slot, offset=8)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_read", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, 0x4000)

    ctx = tc.run_op(cmd_file, "ecc_key_read", 0x4, 0x5, 2, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        #print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        ret |= 1

    tmp = tc.read_output(test_dir, run_name, 0x5000, 1)
    l3_result = tmp & 0xFF
    curve = (tmp >> 8) & 0xFF
    origin = (tmp >> 16) & 0xFF

    A = tc.read_output(test_dir, run_name, 0x5010, 8)

    if (l3_result != 0xc3):
        #print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        ret |= 1

    if not(curve == curve_ref and origin == origin_ref and A == A_ref):
        #print("curve:   ", hex(curve))
        #print("origin:  ", hex(origin))
        #print("A:       ", hex(A))
        tc.print_failed()
        ret |= 1

    if not(ret & 1):
        tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

# ===================================================================================
#   Curve = Ed25519
# ===================================================================================
    cmd_file = tc.get_cmd_file(test_dir)

    Ax_ref = rn.randint(1,2**256 - 1)
    Ay_ref = rn.randint(1,2**256 - 1)
    curve_ref = 0x01
    origin_ref = 0x61

    slot = rn.randint(0, 127)
    pubkey_slot = (slot << 1)+1

    run_name = test_name + "_p256_" + f"{slot}"

    tc.print_run_name(run_name)

    tc.set_key(cmd_file, curve_ref + (origin_ref << 8), ktype=0x4, slot=pubkey_slot, offset=0)
    tc.set_key(cmd_file, Ax_ref, ktype=0x4, slot=pubkey_slot, offset=8)
    tc.set_key(cmd_file, Ay_ref, ktype=0x4, slot=pubkey_slot, offset=16)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_read", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, 0x4000)

    ctx = tc.run_op(cmd_file, "ecc_key_read", 0x4, 0x5, 2, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        #print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        ret |= 2

    tmp = tc.read_output(test_dir, run_name, 0x5000, 1)
    l3_result = tmp & 0xFF
    curve = (tmp >> 8) & 0xFF
    origin = (tmp >> 16) & 0xFF

    Ax = tc.read_output(test_dir, run_name, 0x5010, 8)
    Ay = tc.read_output(test_dir, run_name, 0x5030, 8)

    if (l3_result != 0xc3):
        #print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        ret |= 2

    if not(curve == curve_ref and origin == origin_ref and A == A_ref):
        #print("curve:   ", hex(curve))
        #print("origin:  ", hex(origin))
        #print("Ax:      ", hex(Ax))
        #print("Ay:      ", hex(Ay))
        tc.print_failed()
        ret |= 2

    if not(ret & 2):
        tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

# ===================================================================================
#   Empty Slot
# ===================================================================================
    cmd_file = tc.get_cmd_file(test_dir)

    slot = rn.randint(0, 127)
    pubkey_slot = (slot << 1)+1

    run_name = test_name + "_empty_slot_" + f"{slot}"

    tc.print_run_name(run_name)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_read", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, 0x4000)

    ctx = tc.run_op(cmd_file, "ecc_key_read", 0x4, 0x5, 2, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS != 0xF2):
        #print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        ret |= 4

    tmp = tc.read_output(test_dir, run_name, 0x5000, 1)
    l3_result = tmp & 0xFF

    if (l3_result != 0x3c):
        #print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        ret |= 4

    if not(ret & 4):
        tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm -r {test_dir}")

    sys.exit(ret)
