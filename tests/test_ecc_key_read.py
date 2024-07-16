#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc

if __name__ == "__main__":

    args = tc.parser.parse_args()
    seed = tc.set_seed(args)
    rn.seed(seed)
    print("seed:", seed)
    
    ops_cfg = tc.get_ops_config()
    test_name = "ecc_key_read"

    test_dir = tc.make_test_dir(test_name)

    ret = 0

    insrc = tc.insrc_arr[rn.randint(0,1)]
    outsrc = tc.outsrc_arr[rn.randint(0,1)]

    print("insrc:", insrc)
    print("outsrc:", outsrc)

# ===================================================================================
#   Curve = Ed25519
# ===================================================================================
    cmd_file = tc.get_cmd_file(test_dir)

    A_ref = rn.randint(1,2**256 - 1)
    curve_ref = tc.Ed25519_ID
    origin_ref = 0x01

    slot = rn.randint(0, 127)
    pubkey_slot = (slot << 1)+1

    print("slot:", slot)

    run_name = test_name + "_ed25519_" + f"{slot}"

    tc.print_run_name(run_name)

    tc.set_key(cmd_file, curve_ref + (origin_ref << 8), ktype=0x4, slot=pubkey_slot, offset=0)
    tc.set_key(cmd_file, A_ref, ktype=0x4, slot=pubkey_slot, offset=8)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_read", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ctx = tc.run_op(cmd_file, "ecc_key_read", insrc, outsrc, 2, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        #print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        ret |= 1

    if (SPECT_OP_DATA_OUT_SIZE != 48):
        ret |= 2

    tmp = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result = tmp & 0xFF
    curve = (tmp >> 8) & 0xFF
    origin = (tmp >> 16) & 0xFF

    A = tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, 8, string=True)

    if (l3_result != 0xc3):
        print("L3 RESULT:", hex(l3_result))
        ret |= 1

    # Note: SPECT handles byte string naturally in big-endian order so the debug is easier
    if not(curve == curve_ref and origin == origin_ref and A == A_ref.to_bytes(32, 'big')):
        ret |= 1

    if not(ret & 1):
        tc.print_passed()
    else:
        tc.print_failed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

# ===================================================================================
#   Curve = P256
# ===================================================================================
    cmd_file = tc.get_cmd_file(test_dir)

    Ax_ref = rn.randint(1,2**256 - 1)
    Ay_ref = rn.randint(1,2**256 - 1)
    A_ref = Ax_ref.to_bytes(32, 'big') + Ay_ref.to_bytes(32, 'big')
    curve_ref = tc.P256_ID
    origin_ref = 0x02

    slot = rn.randint(0, 127)
    pubkey_slot = (slot << 1)+1

    run_name = test_name + "_p256_" + f"{slot}"

    tc.print_run_name(run_name)

    tc.set_key(cmd_file, curve_ref + (origin_ref << 8), ktype=0x4, slot=pubkey_slot, offset=0)
    tc.set_key(cmd_file, Ax_ref, ktype=0x4, slot=pubkey_slot, offset=8)
    tc.set_key(cmd_file, Ay_ref, ktype=0x4, slot=pubkey_slot, offset=16)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_read", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ctx = tc.run_op(cmd_file, "ecc_key_read", insrc, outsrc, 2, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        ret |= 2

    if (SPECT_OP_DATA_OUT_SIZE != 80):
        ret |= 2

    tmp = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result = tmp & 0xFF
    curve = (tmp >> 8) & 0xFF
    origin = (tmp >> 16) & 0xFF

    A = tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, 16).to_bytes(64, 'little')

    if (l3_result != 0xc3):
        #print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        ret |= 2

    if not(curve == curve_ref and origin == origin_ref and
           A == A_ref):
        tc.print_failed()
        ret |= 2

    if not(ret & 2):
        tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

# ===================================================================================
#   Invalid Curve Type
# ===================================================================================
    cmd_file = tc.get_cmd_file(test_dir)

    curve_ref = 0x66
    origin_ref = 0x02

    slot = rn.randint(0, 127)
    pubkey_slot = (slot << 1)+1

    run_name = test_name + "_invalid_curve_" + f"{slot}"

    tc.print_run_name(run_name)

    tc.set_key(cmd_file, curve_ref + (origin_ref << 8), ktype=0x4, slot=pubkey_slot, offset=0)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_read", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ctx = tc.run_op(cmd_file, "ecc_key_read", insrc, outsrc, 2, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS != 0xF4):
        ret |= 2

    if (SPECT_OP_DATA_OUT_SIZE != 1):
        ret |= 2

    tmp = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result = tmp & 0xFF

    if (l3_result != 0x12):
        print("L3 RESULT:", hex(l3_result))
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

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ctx = tc.run_op(cmd_file, "ecc_key_read", insrc, outsrc, 2, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS != 0xF2):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        ret |= 4

    if (SPECT_OP_DATA_OUT_SIZE != 1):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        tc.print_failed()
        ret |= 4

    tmp = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result = tmp & 0xFF

    if (l3_result != 0x12):
        print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        ret |= 4

    if not(ret & 4):
        tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm -r {test_dir}")

    sys.exit(ret)
