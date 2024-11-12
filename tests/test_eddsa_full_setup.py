#!/usr/bin/env python3
import sys
import random as rn

import test_common as tc

import models.ed25519 as ed25519

insrc = 0x4
outsrc = 0x5

def eddsa_sequence(test_dir, run_name, keymem, slot, sch, scn, message):

    ########################################################################################################
    #   Set Context
    ########################################################################################################
    rng = [rn.randint(0, 2**256-1) for i in range(20)]
    tc.set_rng(test_dir, rng)

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
        tc.print_failed()
        sys.exit(1)

    ########################################################################################################
    #   Nonce Init
    ########################################################################################################

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    ctx = tc.run_op(cmd_file, "eddsa_nonce_init", insrc, outsrc, 36, ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    ########################################################################################################
    #   Nonce Update
    ########################################################################################################
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
            tc.print_failed()
            sys.exit(1)

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
        tc.print_failed()
        sys.exit(1)

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
        tc.print_failed()
        sys.exit(1)

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
            tc.print_failed()
            sys.exit(1)
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
            tc.print_failed()
            sys.exit(1)

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
                tc.print_failed()
                sys.exit(1)

        ########################################################################################################
        #   E Finish
        ########################################################################################################
        last_block = message_tmp[updates_cnt*128:]

        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)

        tc.write_bytes(cmd_file, last_block, (insrc<<12))

        ctx = tc.run_op(cmd_file, "eddsa_e_finish", insrc, outsrc, len(last_block), ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

        SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

        if (SPECT_OP_STATUS):
            print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
            tc.print_failed()
            sys.exit(1)

    ########################################################################################################
    #   Finish
    ########################################################################################################
    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    #break_s = tc.dump_gpr_on(cmd_file, "bp_dump_eA", [11, 12, 13, 14])
    #break_s += tc.dump_gpr_on(cmd_file, "bp_dump_sG", [7, 8, 9, 10])

    ctx = tc.run_op(cmd_file, "eddsa_finish", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name, old_context=ctx, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    ########################################################################################################
    #   Read and Check
    ########################################################################################################

    result = tc.read_output(test_dir, run_name, (outsrc<<12), 1)

    signature = tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, 16, string=True)

    return signature

def key_store(test_dir, run_name, slot, k):
    cmd_file = tc.get_cmd_file(test_dir)

    rng = [rn.randint(1, 2**256-1) for i in range(10)]
    tc.set_rng(test_dir, rng)

    tc.start(cmd_file)

    input_word = (tc.Ed25519_ID << 24) + (slot << 8) + tc.find_in_list("ecc_key_store", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    tc.write_bytes(cmd_file, k, (insrc<<12) +  0x10)

    ctx = tc.run_op(cmd_file, "ecc_key_store", insrc, outsrc, 3, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    l3_result = tc.read_output(test_dir, run_name, (outsrc << 12), 1)
    l3_result &= 0xFF

    if (l3_result != 0xc3):
        print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        sys.exit(1)

    return 0

def key_read(test_dir, run_name, keymem, slot):
    cmd_file = tc.get_cmd_file(test_dir)

    tc.start(cmd_file)

    input_word = (slot << 8) + tc.find_in_list("ecc_key_read", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ctx = tc.run_op(cmd_file, "ecc_key_read", insrc, outsrc, 2, ops_cfg, test_dir, run_name=run_name, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    key_size = (SPECT_OP_DATA_OUT_SIZE - 16) // 4

    tmp = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result = tmp & 0xFF
    curve = (tmp >> 8) & 0xFF
    origin = (tmp >> 16) & 0xFF
    padding = (tmp >> 24) & 0xFF

    if l3_result != 0xC3:
        print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        sys.exit(1)

    if padding != 0:
        print("Padding: ", hex(padding))
        tc.print_failed()
        sys.exit(1)

    if curve not in [0x1, 0x2]:
        print("Curve: ", hex(curve))
        tc.print_failed()
        sys.exit(1)

    if origin not in [0x1, 0x2]:
        print("Origin: ", hex(origin))
        tc.print_failed()
        sys.exit(1)

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

    tc.print_run_name(run_name)

    test_dir = tc.make_test_dir(test_name)

    k = rn.randint(0, 2**256 - 1).to_bytes(32, 'little')
    sch = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    scn = int.to_bytes(rn.randint(0, 2**32-1), 4, 'little')
    slot = rn.randint(0, 31)
    msg_bitlen = rn.randint(64, 200)*8
    message = int.to_bytes(rn.getrandbits(msg_bitlen), msg_bitlen//8, 'big')

    s, prefix, A_ref = ed25519.key_gen(k)
    sign_ref = ed25519.sign(s, prefix, A_ref, sch, scn, message)

    keymem = f"{test_dir}/{run_name}_keymem.hex"

    if key_store(test_dir, run_name, slot, k) == 1: sys.exit(1)

    sign_1 = eddsa_sequence(test_dir, run_name, keymem, slot, sch, scn, message)
    if sign_1 == None: sys.exit(1)
    if sign_1 != sign_ref:
        print("Signature 1 fail")
        tc.print_failed()
        sys.exit(1)

    sign_2 = eddsa_sequence(test_dir, run_name, keymem, slot, sch, scn, message)
    if sign_2 == None: sys.exit(1)
    if sign_2 != sign_ref:
        print("Signature 2 fail")
        tc.print_failed()
        sys.exit(1)

    A = key_read(test_dir, run_name, keymem, slot)
    if A == None: sys.exit(1)
    if A != A_ref:
        print("Pub key fail")
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

    sys.exit(0)
