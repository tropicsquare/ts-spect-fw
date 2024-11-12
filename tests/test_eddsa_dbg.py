#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc

import models.ed25519 as ed25519

def eddsa_dbg_sequence(s, prefix, A, sch, scn, message, run_name_suffix=""):

    insrc = 0x0
    outsrc = 0x1

    sign_ref = ed25519.sign(s, prefix, A, sch, scn, message)

    ########################################################################################################
    #   Set Context
    ########################################################################################################
    run_name = "eddsa_set_context_dbg" + run_name_suffix
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    tc.write_int256(cmd_file, s, 0x0040)
    tc.write_int256(cmd_file, prefix, 0x0060)

    A_int = int.from_bytes(A, 'big')
    tc.write_int256(cmd_file, A_int, 0x0300)

    tc.write_bytes(cmd_file, sch, 0x00A0)
    tc.write_bytes(cmd_file, scn, 0x00C0)

    ctx = tc.run_op(
        cmd_file, "eddsa_set_context_dbg", insrc, outsrc, 36, ops_cfg, test_dir,
        run_name=run_name
    )

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 0

    if (SPECT_OP_DATA_OUT_SIZE != 0):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        return 0

    ########################################################################################################
    #   Nonce Init
    ########################################################################################################
    run_name = "eddsa_nonce_init" + run_name_suffix
    tc.print_run_name(run_name)

    rng = [rn.randint(0, 2**256-1) for i in range(10)]
    tc.set_rng(test_dir, rng)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    ctx = tc.run_op(
        cmd_file, "eddsa_nonce_init", insrc, outsrc, 36, ops_cfg, test_dir,
        run_name=run_name, old_context=ctx
    )

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 0

    if (SPECT_OP_DATA_OUT_SIZE != 0):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        return 0

    ########################################################################################################
    #   Nonce Update
    ########################################################################################################
    updates_cnt = len(message) // 144
    for i in range(0, updates_cnt):
        block = message[i*144:i*144+144]
        run_name = f"eddsa_nonce_update_{i}" + run_name_suffix
        tc.print_run_name(run_name)

        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)

        tc.write_bytes(cmd_file, block, (insrc<<12))
        ctx = tc.run_op(
            cmd_file, "eddsa_nonce_update", insrc, outsrc, 144, ops_cfg, test_dir,
            run_name=run_name, old_context=ctx
        )

        SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

        if (SPECT_OP_STATUS):
            print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
            return 0

        if (SPECT_OP_DATA_OUT_SIZE != 0):
            print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
            return 0

    ########################################################################################################
    #   Nonce Update
    ########################################################################################################
    last_block_tmac = message[updates_cnt*144:]

    run_name = "eddsa_nonce_finish" + run_name_suffix
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    tc.write_bytes(cmd_file, last_block_tmac, (insrc<<12))

    ctx = tc.run_op(
        cmd_file, "eddsa_nonce_finish", insrc, outsrc, len(last_block_tmac), ops_cfg, test_dir,
        run_name=run_name, old_context=ctx
    )

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 0

    if (SPECT_OP_DATA_OUT_SIZE != 0):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        return 0

    ########################################################################################################
    #   R Part
    ########################################################################################################
    run_name = "eddsa_R_part" + run_name_suffix
    tc.print_run_name(run_name)

    rng = [rn.randint(0, 2**256-1) for i in range(10)]
    tc.set_rng(test_dir, rng)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    ctx = tc.run_op(
        cmd_file, "eddsa_R_part", insrc, outsrc, 0, ops_cfg, test_dir,
        run_name=run_name, old_context=ctx
    )

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 0

    if (SPECT_OP_DATA_OUT_SIZE != 0):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        return 0

    ########################################################################################################
    #   E at once
    ########################################################################################################
    run_name = "eddsa_e_at_once" + run_name_suffix
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    tc.write_bytes(cmd_file, message, (insrc<<12))

    ctx = tc.run_op(
        cmd_file, "eddsa_e_at_once", insrc, outsrc, len(message), ops_cfg, test_dir,
        run_name=run_name, old_context=ctx
    )

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 0

    if (SPECT_OP_DATA_OUT_SIZE != 0):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        return 0

    ########################################################################################################
    #   Finish
    ########################################################################################################
    run_name = "eddsa_finish" + run_name_suffix
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    ctx = tc.run_op(
        cmd_file, "eddsa_finish", insrc, outsrc, 0, ops_cfg, test_dir,
        run_name=run_name, old_context=ctx
    )

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 0

    if (SPECT_OP_DATA_OUT_SIZE != 80):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        return 0

    ########################################################################################################
    #   Read and Check
    ########################################################################################################

    result = tc.read_output(test_dir, run_name, (outsrc<<12), 1)

    signature = tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, 16, string=True)

    return sign_ref == signature

if __name__ == "__main__":
    defines_set = tc.get_main_defines()
    if "DEBUG_OPS" not in defines_set:
        tc.print_test_skipped("Debug ops are disabled.")
        sys.exit(0)
    if "IN_SRC_EN" not in defines_set or "OUT_SRC_EN" not in defines_set:
        tc.print_test_skipped("INOUT SRC feature disabled, it must be enabled for eddsa sequence to work.")
        sys.exit(0)

    args = tc.parser.parse_args()
    seed = tc.set_seed(args)
    rn.seed(seed)
    print("seed:", seed)

    ret = 0

    ops_cfg = tc.get_ops_config()
    test_name = "eddsa_dbg"

    test_dir = tc.make_test_dir(test_name)

    k = rn.randint(0, 2**256-1).to_bytes(32, 'little')
    s, prefix, A = ed25519.key_gen(k)

    sch = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    scn = int.to_bytes(rn.randint(0, 2**32-1), 4, 'little')

    ########################################################################################################
    #   Test message len < 64
    ########################################################################################################

    msg_bitlen = rn.randint(1, 63)*8
    message = int.to_bytes(rn.getrandbits(msg_bitlen), msg_bitlen//8, 'big')

    if not eddsa_dbg_sequence(s, prefix, A, sch, scn, message):
        tc.print_failed()
        ret = 1
    else:
        tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm -r {test_dir}")

    sys.exit(ret)
