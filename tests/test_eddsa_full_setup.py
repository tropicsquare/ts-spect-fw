#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc

import models.ed25519 as ed25519

insrc = 0x4
outsrc = 0x5

def eddsa_sequence(test_dir, run_name, keymem, slot, sch, scn, message):

    smodq = s % ed25519.q

    ########################################################################################################
    #   Set Context
    ########################################################################################################
    
    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("eddsa_set_context", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    tc.write_bytes(cmd_file, sch, 0x00A0)
    tc.write_bytes(cmd_file, scn, 0x00C0)

    ctx = tc.run_op(cmd_file, "eddsa_set_context", insrc, outsrc, 36, ops_cfg, test_dir, run_name=run_name, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return None

    ########################################################################################################
    #   Nonce Init
    ########################################################################################################

    rng = [rn.randint(0, 2**256-1) for i in range(10)]
    tc.set_rng(test_dir, rng)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    ctx = tc.run_op(cmd_file, "eddsa_nonce_init", insrc, outsrc, 36, ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return None

    ########################################################################################################
    #   Nonce Update
    ########################################################################################################
    m_blocks_tmac = []

    updates_cnt = len(message) // 144
    for i in range(0, updates_cnt):
        block = message[i*144:i*144+144]

        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)

        tc.write_bytes(cmd_file, block, (insrc<<12))
        ctx = tc.run_op(cmd_file, "eddsa_nonce_update", insrc, outsrc, 144, ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

        SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

        if (SPECT_OP_STATUS):
            print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
            return None

    ########################################################################################################
    #   Nonce Update
    ########################################################################################################
    last_block_tmac = message[updates_cnt*144:]

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    tc.write_bytes(cmd_file, last_block_tmac, (insrc<<12))

    ctx = tc.run_op(cmd_file, "eddsa_nonce_finish", insrc, outsrc, len(last_block_tmac), ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return None

    ########################################################################################################
    #   R Part
    ########################################################################################################

    rng = [rn.randint(0, 2**256-1) for i in range(10)]
    tc.set_rng(test_dir, rng)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    ctx = tc.run_op(cmd_file, "eddsa_R_part", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return None

    if len(message) < 64:
        ########################################################################################################
        #   E at once
        ########################################################################################################

        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)

        tc.write_bytes(cmd_file, message, (insrc<<12))

        ctx = tc.run_op(cmd_file, "eddsa_e_at_once", insrc, outsrc, len(message), ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

        SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

        if (SPECT_OP_STATUS):
            print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
            return None
    else:
        ########################################################################################################
        #   E Prep
        ########################################################################################################
        m_block_prep = message[:64]

        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)

        tc.write_bytes(cmd_file, m_block_prep, (insrc<<12))

        ctx = tc.run_op(cmd_file, "eddsa_e_prep", insrc, outsrc, 64, ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

        SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

        if (SPECT_OP_STATUS):
            print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
            return None

        ########################################################################################################
        #   E Update
        ########################################################################################################
        message_tmp = message[64:]
        updates_cnt = len(message_tmp) // 128

        for i in range(0, updates_cnt):
            block = message_tmp[i*128:i*128+128]

            cmd_file = tc.get_cmd_file(test_dir)
            tc.start(cmd_file)

            tc.write_bytes(cmd_file, block, (insrc<<12))
            ctx = tc.run_op(cmd_file, "eddsa_e_update", insrc, outsrc, 128, ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

            SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

            if (SPECT_OP_STATUS):
                print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
                return None

        ########################################################################################################
        #   E Finish
        ########################################################################################################
        tc.print_run_name(run_name)

        last_block = message_tmp[updates_cnt*128:]

        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)

        tc.write_bytes(cmd_file, last_block, (insrc<<12))

        ctx = tc.run_op(cmd_file, "eddsa_e_finish", insrc, outsrc, len(last_block), ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

        SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

        if (SPECT_OP_STATUS):
            print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
            return None

    ########################################################################################################
    #   Finish
    ########################################################################################################
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    #break_s = tc.dump_gpr_on(cmd_file, "bp_dump_eA", [11, 12, 13, 14])
    #break_s += tc.dump_gpr_on(cmd_file, "bp_dump_sG", [7, 8, 9, 10])

    ctx = tc.run_op(cmd_file, "eddsa_finish", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return None

    ########################################################################################################
    #   Read and Check
    ########################################################################################################

    result = tc.read_output(test_dir, run_name, (outsrc<<12), 1)

    signature = tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, 16, string=True)

    return signature

def key_store(test_dir, run_name, slot, k):
    cmd_file = tc.get_cmd_file(test_dir)

    tc.print_run_name(run_name)

    tc.start(cmd_file)

    input_word = (tc.Ed25519_ID << 24) + (slot << 8) + tc.find_in_list("ecc_key_store", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    tc.write_bytes(cmd_file, k, (insrc<<12) +  0x10)

    ctx = tc.run_op(cmd_file, "ecc_key_store", insrc, outsrc, 3, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    l3_result = tc.read_output(test_dir, run_name, (outsrc << 12), 1)
    l3_result &= 0xFF

    if (l3_result != 0xc3):
        print("L3 RESULT:", hex(l3_result))
        return 1

    return 0

def key_read(test_dir, run_name, keymem, slot):
    cmd_file = tc.get_cmd_file(test_dir)

    tc.print_run_name(run_name)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_read", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ctx = tc.run_op(cmd_file, "ecc_key_read", insrc, outsrc, 2, ops_cfg, test_dir, run_name=run_name, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        return None

    key_size = (SPECT_OP_DATA_OUT_SIZE - 16) // 4

    tmp = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result = tmp & 0xFF
    curve = (tmp >> 8) & 0xFF
    origin = (tmp >> 16) & 0xFF

    A = tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, key_size).to_bytes(key_size*4, 'little')

    return A

if __name__ == "__main__":
    args = tc.parser.parse_args()
    seed = tc.set_seed(args)
    rn.seed(seed)
    print("seed:", seed)

    ops_cfg = tc.get_ops_config()
    test_name = "eddsa_full_setup"
    run_name = test_name

    test_dir = tc.make_test_dir(test_name)

    k = rn.randint(0, 2**256 - 1).to_bytes(32, 'little')
    sch = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    scn = int.to_bytes(rn.randint(0, 2**32-1), 4, 'little')
    slot = rn.randint(0, 7)
    msg_bitlen = rn.randint(64, 200)*8
    message = int.to_bytes(rn.getrandbits(msg_bitlen), msg_bitlen//8, 'big')

    s, prefix = ed25519.secret_expand(k)
    A_ref = ed25519.secret_to_public(k)
    sign_ref = ed25519.sign(s, prefix, A_ref, sch, scn, message)

    keymem = f"{test_dir}/{run_name}_keymem.hex"

    if key_store(test_dir, run_name, slot, k) == 1: sys.exit(1)
    sign = eddsa_sequence(test_dir, run_name, keymem, slot, sch, scn, message)
    if sign == None: sys.exit(1)
    A = key_read(test_dir, run_name, keymem, slot)
    if A == None: sys.exit(1)

    #print("=====================================================================")
    #print("k   :", k.hex())
    #print("sch :", sch.hex())
    #print("scn :", scn.hex())
    #print("=====================================================================")
    #print("s      :", hex(s))
    #print("prefix :", prefix.hex())
    #print("=====================================================================")
    #print()
    #print("message:")
    #print(message.hex())
    #print()
#
    #print("=====================================================================")
    #print("sign    :", sign.hex())
    #print("sign ref:", sign_ref.hex())
    #print("=====================================================================")
    #print("A    :", A.hex())
    #print("A ref:", A_ref.hex())
    #print("=====================================================================")
    #print()

    if not(
        sign == sign_ref and
        A == A_ref
    ): 
        tc.print_failed()
        sys.exit(1)
    tc.print_passed()

    sys.exit(0)
