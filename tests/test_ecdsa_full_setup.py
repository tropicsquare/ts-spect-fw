#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc
import models.p256 as p256

insrc = 0x4
outsrc = 0x5

def ecdsa_sign(test_dir, run_name, keymem, slot, sch, scn, z):
    cmd_file = tc.get_cmd_file(test_dir)

    tc.write_bytes(cmd_file, z, (insrc<<12) + 0x10)
    tc.write_bytes(cmd_file, sch, 0x00A0)
    tc.write_bytes(cmd_file, scn, 0x00C0)

    input_word = (slot << 8) + tc.find_in_list("ecdsa_sign", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ctx = tc.run_op(cmd_file, "ecdsa_sign", insrc, outsrc, 0, ops_cfg, test_dir, run_name=run_name, keymem=keymem)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        return None

    if (SPECT_OP_DATA_OUT_SIZE != 80):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        return 0

    l3_result = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result &= 0xFF

    return tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, 16, string=True)

def key_store(test_dir, run_name, slot, k):
    cmd_file = tc.get_cmd_file(test_dir)

    tc.print_run_name(run_name)

    tc.start(cmd_file)

    input_word = (tc.P256_ID << 24) + (slot << 8) + tc.find_in_list("ecc_key_store", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    tc.write_bytes(cmd_file, k, (insrc<<12) +  0x10)

    ctx = tc.run_op(cmd_file, "ecc_key_store", insrc, outsrc, 3, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1
    
    if (SPECT_OP_DATA_OUT_SIZE != 0):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        return 0

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

    if (SPECT_OP_DATA_OUT_SIZE != 80):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        return 0

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
    test_name = "ecdsa_full_setup"
    run_name = test_name

    tc.print_run_name(run_name)

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    rng = [rn.randint(0, 2**256-1) for i in range(16)]
    tc.set_rng(test_dir, rng)

    slot = rn.randint(0, 7)

    k = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')

    sch = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    scn = int.to_bytes(rn.randint(0, 2**32-1), 4, 'little')

    d, w, Ax_ref, Ay_ref = p256.key_gen(k)
    A_ref = Ax_ref.to_bytes(32, 'big') + Ay_ref.to_bytes(32, 'big')

    z = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')

    r_ref, s_ref = p256.sign(d, w, sch, scn, z)

    sign_ref = r_ref.to_bytes(32, 'big') + s_ref.to_bytes(32, 'big')

    keymem = f"{test_dir}/{run_name}_keymem.hex"

    if key_store(test_dir, run_name, slot, k) == 1: sys_exit(1)
    sign = ecdsa_sign(test_dir, run_name, keymem, slot, sch, scn, z)
    if sign == None: sys_exit(1)
    A = key_read(test_dir, run_name, keymem, slot)
    if A == None: sys_exit(1)

    print("=====================================================================")
    print("k   :", k.hex())
    print("sch :", sch.hex())
    print("scn :", scn.hex())
    print("=====================================================================")
    print("d :", hex(d))
    print("w :", w.hex())
    print("=====================================================================")
    print()
    print("z:")
    print(z.hex())
    print()

    print("=====================================================================")
    print("sign    :", sign.hex())
    print("sign ref:", sign_ref.hex())
    print("=====================================================================")
    print("A       :", A.hex())
    print("A ref   :", A_ref.hex())
    print("=====================================================================")

    if not(
        sign == sign_ref and
        A == A_ref
    ): 
        tc.print_failed()
        sys.exit(1)
    tc.print_passed()

    sys.exit(0)
