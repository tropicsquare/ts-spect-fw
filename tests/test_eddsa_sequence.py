#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc

import models.ed25519 as ed25519

def eddsa_sequence(s, prefix, A, slot, sch, scn, message):

    sign_ref = ed25519.sign(s, prefix, A, sch, scn, message)

    ########################################################################################################
    #   Set Context
    ########################################################################################################
    run_name = "eddsa_set_context"
    tc.print_run_name(run_name)
    
    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    prefix_int = int.from_bytes(prefix, 'big')
    tc.set_key(cmd_file, key=s,          ktype=0x04, slot=(slot<<1), offset=0)
    tc.set_key(cmd_file, key=prefix_int, ktype=0x04, slot=(slot<<1), offset=8)

    metadata = 0x02
    tc.set_key(cmd_file, key=metadata,  ktype=0x04, slot=(slot<<1)+1, offset=0)
    A_int = int.from_bytes(A, 'big')
    tc.set_key(cmd_file, key=A_int,     ktype=0x04, slot=(slot<<1)+1, offset=8)

    input_word = (slot << 8) + tc.find_in_list(run_name, ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    tc.write_bytes(cmd_file, sch, 0x00A0)
    tc.write_bytes(cmd_file, scn, 0x00C0)

    ctx = tc.run_op(cmd_file, "eddsa_set_context", insrc, outsrc, 36, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    ########################################################################################################
    #   Nonce Init
    ########################################################################################################
    run_name = "eddsa_nonce_init"
    tc.print_run_name(run_name)

    rng = [rn.randint(0, 2**256-1) for i in range(4)]
    tc.set_rng(test_dir, rng)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    ctx = tc.run_op(cmd_file, "eddsa_nonce_init", insrc, outsrc, 36, ops_cfg, test_dir, run_name=run_name, old_context=ctx)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    ########################################################################################################
    #   Nonce Update
    ########################################################################################################
    m_blocks_tmac = []

    updates_cnt = len(message) // 144
    for i in range(0, updates_cnt):
        block = message[i*144:i*144+144]
        run_name = f"eddsa_nonce_update_{i}"
        tc.print_run_name(run_name)

        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)

        tc.write_bytes(cmd_file, block, (insrc<<12))
        ctx = tc.run_op(cmd_file, "eddsa_nonce_update", insrc, outsrc, 144, ops_cfg, test_dir, run_name=run_name, old_context=ctx)

        SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

        if (SPECT_OP_STATUS):
            print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
            return 1

    ########################################################################################################
    #   Nonce Update
    ########################################################################################################
    last_block_tmac = message[updates_cnt*144:]

    run_name = "eddsa_nonce_finish"
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    tc.write_bytes(cmd_file, last_block_tmac, (insrc<<12))

    ctx = tc.run_op(cmd_file, "eddsa_nonce_finish", insrc, outsrc, len(last_block_tmac), ops_cfg, test_dir, run_name=run_name, old_context=ctx)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    ########################################################################################################
    #   R Part
    ########################################################################################################
    run_name = "eddsa_R_part"
    tc.print_run_name(run_name)

    rng = [rn.randint(0, 2**256-1) for i in range(4)]

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    ctx = tc.run_op(cmd_file, "eddsa_R_part", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name, old_context=ctx)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    ########################################################################################################
    #   E Prep
    ########################################################################################################
    m_block_prep = message[:64]

    run_name = "eddsa_e_prep"
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    print("e prep block ", m_block_prep.hex())
    tc.write_bytes(cmd_file, m_block_prep, (insrc<<12))

    ctx = tc.run_op(cmd_file, "eddsa_e_prep", insrc, outsrc, 64, ops_cfg, test_dir, run_name=run_name, old_context=ctx)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    ########################################################################################################
    #   E Update
    ########################################################################################################
    message_tmp = message[64:]
    updates_cnt = len(message_tmp) // 128
    print(message_tmp.hex())



    for i in range(0, updates_cnt):
        block = message_tmp[i*128:i*128+128]
        run_name = f"eddsa_e_update_{i}"
        tc.print_run_name(run_name)

        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)

        print("e update block", i, block.hex())
        tc.write_bytes(cmd_file, block, (insrc<<12))
        ctx = tc.run_op(cmd_file, "eddsa_e_update", insrc, outsrc, 128, ops_cfg, test_dir, run_name=run_name, old_context=ctx)

        SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

        if (SPECT_OP_STATUS):
            print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
            return 1

    ########################################################################################################
    #   E Finish
    ########################################################################################################
    run_name = "eddsa_e_finish"
    tc.print_run_name(run_name)

    last_block = message_tmp[updates_cnt*128:]

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    print("e finish block", last_block.hex())
    tc.write_bytes(cmd_file, last_block, (insrc<<12))

    ctx = tc.run_op(cmd_file, "eddsa_e_finish", insrc, outsrc, len(last_block), ops_cfg, test_dir, run_name=run_name, old_context=ctx)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    ########################################################################################################
    #   Finish
    ########################################################################################################
    run_name = "eddsa_finish"
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)

    #break_s = tc.dump_gpr_on(cmd_file, "bp_dump_eA", [11, 12, 13, 14])
    #break_s += tc.dump_gpr_on(cmd_file, "bp_dump_sG", [7, 8, 9, 10])

    ctx = tc.run_op(cmd_file, "eddsa_finish", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name, old_context=ctx)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    ########################################################################################################
    #   Read and Check
    ########################################################################################################

    result = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    print("result:", hex(result))

    sref_int = int.from_bytes(sign_ref, 'big')
    print("signature_ref:", hex(sref_int))

    signature = tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, 16)
    print("signature:    ", hex(signature))

    print(sref_int == signature)

    return 0

if __name__ == "__main__":

    #seed = rn.randint(0, 2**32-1)
    seed = 3038690163
    rn.seed(seed)
    print("seed:", seed)

    ops_cfg = tc.get_ops_config()
    test_name = "eddsa_sequence"

    test_dir = tc.make_test_dir(test_name)

    k = rn.randint(0, 2**256-1).to_bytes(32, 'little')
    s, prefix = ed25519.secret_expand(k)
    A = ed25519.secret_to_public(k)

    print("A:", A.hex())

    sch = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    scn = int.to_bytes(rn.randint(0, 2**32-1), 4, 'little')

    slot = rn.randint(0, 7)

    insrc = 0x0
    outsrc = 0x1

    ########################################################################################################
    #   Test message len >= 64
    ########################################################################################################

    msg_bitlen = rn.randint(64, 400)*8
    message = int.to_bytes(rn.getrandbits(msg_bitlen), msg_bitlen//8, 'big')

    print("message", message.hex())

    ret = eddsa_sequence(s, prefix, A, slot, sch, scn, message)

    if ret:
        tc.print_failed()
        sys.exit(ret)

    sys.exit(0)

    ########################################################################################################
    #   Test message len < 64
    ########################################################################################################

    msg_bitlen = rn.randint(0, 63)*8
    message = int.to_bytes(rn.getrandbits(msg_bitlen), msg_bitlen//8, 'big')
    
    ret = eddsa_sequence(s, prefix, A, slot, sch, scn, message)

    if ret:
        tc.print_failed()
        sys.exit(ret)

    sys.exit(0)    
