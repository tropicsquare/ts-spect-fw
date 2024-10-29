#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc

origin_str = {
    0x1 : "gen",
    0x2 : "store"
}

curve_str = {
    tc.Ed25519_ID: "ed25519",
    tc.P256_ID: "p256"
}

test_name = "ecc_key_read"

METADATA_ERR_TYPE = [
    "slot_type", "slot_number", "origin", "curve"
]

def gen_and_set_key(curve, slot, cmd_file) -> bytes:
    if curve == tc.Ed25519_ID:
        A_ref = rn.randint(1,2**256 - 1)
        tc.set_key(cmd_file, A_ref, ktype=0x4, slot=(2*slot + 1), offset=5*8)
        return A_ref.to_bytes(32, 'big')
    else:
        Ax_ref = rn.randint(1,2**256 - 1)
        Ay_ref = rn.randint(1,2**256 - 1)
        tc.set_key(cmd_file, Ax_ref, ktype=0x4, slot=(2*slot + 1), offset=5*8)
        tc.set_key(cmd_file, Ay_ref, ktype=0x4, slot=(2*slot + 1), offset=6*8)
        return Ax_ref.to_bytes(32, 'big') + Ay_ref.to_bytes(32, 'big')

def read_key(curve, outsrc, run_name) -> bytes:
    if curve == tc.Ed25519_ID:
        size = 8
    else:
        size = 16
    return tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, size).to_bytes(size*4, 'little')

def test_process(test_dir, insrc, outsrc, curve, origin, empty_slot=False, invalid_metadata=None):

    cmd_file = tc.get_cmd_file(test_dir)

    slot = rn.randint(0, 127)
    priv_slot = 2*slot
    pub_slot = priv_slot+1

    run_name = f"{test_name}_{curve_str[curve]}_{origin_str[origin]}"
    if empty_slot:
        run_name += "_empty_slot"
    if invalid_metadata is not None:
        run_name += f"_{invalid_metadata}"

    tc.print_run_name(run_name)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_read", ops_cfg)["id"]
    tc.write_int32(cmd_file, input_word, (insrc<<12))

    if empty_slot:
        ctx = tc.run_op(
            cmd_file, "ecc_key_read", insrc, outsrc, 2, ops_cfg, test_dir, run_name=run_name
        )
    else:
        A_ref = gen_and_set_key(curve, slot, cmd_file)
        _, _ = tc.gen_and_set_metadata(curve, slot, origin, cmd_file, invalid_metadata)
        _ = tc.run_op(cmd_file, "ecc_key_read", insrc, outsrc, 2, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if empty_slot == False and invalid_metadata is None: # No fault
        if (SPECT_OP_STATUS):
            print("SPECT_OP_STATUS", hex(SPECT_OP_STATUS))
            return 1

        if curve == tc.Ed25519_ID:
            if (SPECT_OP_DATA_OUT_SIZE != 48):
                print("SPECT_OP_DATA_OUT_SIZE", hex(SPECT_OP_DATA_OUT_SIZE))
                return 1
        else:
            if (SPECT_OP_DATA_OUT_SIZE != 80):
                print("SPECT_OP_DATA_OUT_SIZE", hex(SPECT_OP_DATA_OUT_SIZE))
                return 1

        tmp = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
        l3_result = tmp & 0xFF
        r_curve = (tmp >> 8) & 0xFF
        r_origin = (tmp >> 16) & 0xFF

        if (l3_result != 0xc3):
            print("L3 RESULT:", hex(l3_result))
            return 1

        if (r_curve != curve):
            print("CURVE", hex(r_curve))
            return 1

        if (r_origin != origin):
            print("ORIGIN", hex(r_origin))
            return 1

        A = read_key(curve, outsrc, run_name)

        if (A != A_ref):
            print("A    ", A.hex())
            print("A_ref", A_ref.hex())
            return 1

        return 0
    else: # Fault
        if empty_slot == True:
            status_expected = 0xF2
        elif invalid_metadata == "curve":
            status_expected = 0xF4
        else:
            status_expected = 0xF6

        if (SPECT_OP_STATUS != status_expected):
            print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
            return 1

        if (SPECT_OP_DATA_OUT_SIZE != 1):
            print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
            return 1

        tmp = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
        l3_result = tmp & 0xFF

        if (l3_result != 0x12):
            print("L3 RESULT:", hex(l3_result))
            return 1

        return 0

if __name__ == "__main__":

    args = tc.parser.parse_args()
    seed = tc.set_seed(args)
    rn.seed(seed)
    print("seed:", seed)

    defines_set = tc.get_main_defines()

    ops_cfg = tc.get_ops_config()
    test_name = "ecc_key_read"

    test_dir = tc.make_test_dir(test_name)

    ret = 0

    insrc = 0x4
    if "IN_SRC_EN" in defines_set:
        insrc = tc.insrc_arr[rn.randint(0,1)]

    outsrc = 0x5
    if "OUT_SRC_EN" in defines_set:
        outsrc = tc.outsrc_arr[rn.randint(0,1)]

    print("insrc:", insrc)
    print("outsrc:", outsrc)

    fail_flag = 0

    # ===================================================================================
    #   Curve = Ed25519, Generated
    # ===================================================================================
    if(test_process(test_dir, insrc, outsrc, curve=tc.Ed25519_ID, origin=0x1)):
        tc.print_failed()
        fail_flag = fail_flag | 1
    else:
        tc.print_passed()

    # ===================================================================================
    #   Curve = P-256, Stored
    # ===================================================================================
    if(test_process(test_dir, insrc, outsrc, curve=tc.P256_ID, origin=0x2)):
        tc.print_failed()
        fail_flag = fail_flag | 1
    else:
        tc.print_passed()

    # ===================================================================================
    #   Empty slot
    # ===================================================================================
    if(test_process(test_dir, insrc, outsrc, curve=tc.P256_ID, origin=0x2, empty_slot=True)):
        tc.print_failed()
        fail_flag = fail_flag | 1
    else:
        tc.print_passed()

    # ===================================================================================
    #   Invalid metadata
    # ===================================================================================
    for medatata_err in METADATA_ERR_TYPE:
        if(test_process(test_dir, insrc, outsrc, curve=tc.P256_ID, origin=0x2, invalid_metadata=medatata_err)):
            tc.print_failed()
            fail_flag = fail_flag | 1
        else:
            tc.print_passed()

    sys.exit(fail_flag)
