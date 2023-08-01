#!/usr/bin/env python3
import sys
import random as rn

import test_common as tc

if __name__ == "__main__":

    seed = rn.randint(0, 2**32-1)
    rn.seed(seed)
    print("seed:", seed)
    
    ops_cfg = tc.get_ops_config()
    test_name = "ecc_key_erase"

    test_dir = tc.make_test_dir(test_name)

    ret = 0

# ===================================================================================
#   Full Slot
# ===================================================================================

    cmd_file = tc.get_cmd_file(test_dir)

    slot = rn.randint(0, 127)
    privkey_slot = (slot << 1)
    pubkey_slot = (slot << 1)+1

    run_name = test_name + "_full_slot_" + f"{slot}"
    tc.print_run_name(run_name)

    tc.set_key(cmd_file, 1, ktype=0x4, slot=privkey_slot, offset = 0)
    tc.set_key(cmd_file, 1, ktype=0x4, slot=pubkey_slot, offset = 0)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_erase", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, 0x4000)

    ctx = tc.run_op(cmd_file, "ecc_key_erase", 0x4, 0x5, 2, ops_cfg, test_dir, run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        ret |= 1

    tmp = tc.read_output(test_dir, run_name, 0x5000, 1)
    l3_result = tmp & 0xFF

    if (l3_result != 0xc3):
        print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        ret |= 1

    kmem_data, kmem_slots = tc.parse_key_mem(test_dir, run_name)

    if kmem_slots[0x4][privkey_slot]:
        print("Private Key Slot is not empty.")
        tc.print_failed()
        ret != 1

    if kmem_slots[0x4][pubkey_slot]:
        print("Public Key Slot is not empty.")
        tc.print_failed()
        ret != 1

    if not(ret & 1):
        tc.print_passed()

# ===================================================================================
#   Empty Slot
# ===================================================================================

    cmd_file = tc.get_cmd_file(test_dir)

    slot = rn.randint(0, 127)
    privkey_slot = (slot << 1)
    pubkey_slot = (slot << 1)+1

    run_name = test_name + "_empty_slot_" + f"{slot}"
    tc.print_run_name(run_name)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_erase", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, 0x4000)

    ctx = tc.run_op(cmd_file, "ecc_key_erase", 0x4, 0x5, 2, ops_cfg, test_dir, run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS != 0xF2):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        ret |= 2

    tmp = tc.read_output(test_dir, run_name, 0x5000, 1)
    l3_result = tmp & 0xFF

    if (l3_result != 0x3c):
        print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        ret |= 2

    if not(ret & 2):
        tc.print_passed()
