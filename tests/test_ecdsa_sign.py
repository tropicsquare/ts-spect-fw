#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc
import models.p256 as p256

def test_proc(test_type: str):
    run_name = f"{test_name}_{test_type}"
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    rng = [rn.randint(0, 2**256-1) for i in range(16)]
    tc.set_rng(test_dir, rng)

    insrc = tc.insrc_arr[rn.randint(0,1)]
    outsrc = tc.outsrc_arr[rn.randint(0,1)]

    slot = rn.randint(0, 7)

    input_word = (slot << 8) + tc.find_in_list("ecdsa_sign", ops_cfg)["id"]
    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ########################################################################################################
    # Empty Slot
    ########################################################################################################    
    if test_type == "empty_slot":
        tc.run_op(cmd_file, "ecdsa_sign", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name)
        SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)
        l3_result = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
        l3_result &= 0xFF
        if SPECT_OP_STATUS != 0xF2:
            print("SPECT_OP_STATUS", hex(SPECT_OP_STATUS))
            return 0

        if SPECT_OP_DATA_OUT_SIZE != 1:
            print("SPECT_OP_DATA_OUT_SIZE", hex(SPECT_OP_DATA_OUT_SIZE))
            return 0

        if l3_result != 0x12:
            print("l3_result", hex(l3_result))
            return 0

        return 1
    ########################################################################################################

    # Generate test vector
    d, w, Ax, Ay = p256.key_gen(int.to_bytes(rn.randint(0, 2**256-1), 32, 'big'))

    sch = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    scn = int.to_bytes(rn.randint(0, 2**32-1), 4, 'little')

    z = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')

    wint = int.from_bytes(w, 'big')
    tc.set_key(cmd_file, key=d,          ktype=0x04, slot=(slot<<1),   offset=0)
    tc.set_key(cmd_file, key=wint,       ktype=0x04, slot=(slot<<1),   offset=8)

    if test_type == "invalid_key_type":
        tc.set_key(cmd_file, key=0x1234, ktype=0x04, slot=(slot<<1)+1, offset=0)
    else:
        tc.set_key(cmd_file, key=tc.P256_ID, ktype=0x04, slot=(slot<<1)+1, offset=0)
    tc.set_key(cmd_file, key=Ax,         ktype=0x04, slot=(slot<<1)+1, offset=8)
    tc.set_key(cmd_file, key=Ay,         ktype=0x04, slot=(slot<<1)+1, offset=16)

    tc.write_bytes(cmd_file, z, (insrc<<12) + 0x10)
    tc.write_bytes(cmd_file, sch, 0x00A0)
    tc.write_bytes(cmd_file, scn, 0x00C0)

    r_ref, s_ref = p256.sign(d, w, sch, scn, z)
    signature_ref = r_ref.to_bytes(32, 'big') + s_ref.to_bytes(32, 'big')

    # Run Op
    tc.run_op(cmd_file, "ecdsa_sign", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)
    l3_result = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result &= 0xFF

    ########################################################################################################
    # Invalid Key Type
    ########################################################################################################    
    if test_type == "invalid_key_type":
        if SPECT_OP_STATUS != 0xF4:
            print("SPECT_OP_STATUS", hex(SPECT_OP_STATUS))
            return 0

        if SPECT_OP_DATA_OUT_SIZE != 1:
            print("SPECT_OP_DATA_OUT_SIZE", hex(SPECT_OP_DATA_OUT_SIZE))
            return 0

        if l3_result != 0x12:
            print("l3_result", hex(l3_result))
            return 0
        return 1
    ########################################################################################################
    # Valid
    ########################################################################################################    
    else:
        if SPECT_OP_STATUS != 0x00:
            print("SPECT_OP_STATUS", hex(SPECT_OP_STATUS))
            return 0

        if l3_result != 0xc3:
            print("l3_result", hex(l3_result))
            return 0

        sing_size = (SPECT_OP_DATA_OUT_SIZE - 16) // 4
        signature = tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, sing_size, string=True)

        if not(signature_ref == signature):
            print("signature    ", signature.hex())
            print("signature_ref", signature_ref.hex())
            return 0

        return 1
    return 0

if __name__ == "__main__":

    args = tc.parser.parse_args()
    seed = tc.set_seed(args)
    rn.seed(seed)
    print("seed:", seed)

    ops_cfg = tc.get_ops_config()
    test_name = "ecdsa_sign"
    test_dir = tc.make_test_dir(test_name)

    res = 0

    if not test_proc("empty_slot"):
        res |= 1
        tc.print_failed()
    else:
        tc.print_passed()

    if not test_proc("invalid_key_type"):
        res |= 1
        tc.print_failed()
    else:
        tc.print_passed()

    if not test_proc("valid"):
        res |= 1
        tc.print_failed()
    else:
        tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm -r {test_dir}")

    sys.exit(res)