#!/usr/bin/env python3
import sys
import random as rn

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
        print("SPECT_OP_STATUS 1:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    if (SPECT_OP_DATA_OUT_SIZE != 80):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
        tc.print_failed()
        sys.exit(1)

    l3_result = tc.read_output(test_dir, run_name, (outsrc<<12), 1)
    l3_result &= 0xFF

    if (l3_result != 0xc3):
        print("L3 RESULT:", hex(l3_result))
        tc.print_failed()
        sys.exit(1)

    return tc.read_output(test_dir, run_name, (outsrc<<12)+0x10, 16, string=True)

def key_store(test_dir, run_name, slot, k):
    cmd_file = tc.get_cmd_file(test_dir)

    rng = [rn.randint(1, 2**256-1) for i in range(10)]
    tc.set_rng(test_dir, rng)

    tc.start(cmd_file)

    input_word = (tc.P256_ID << 24) + (slot << 8) + tc.find_in_list("ecc_key_store", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    tc.write_bytes(cmd_file, k, (insrc<<12) +  0x10)

    ctx = tc.run_op(cmd_file, "ecc_key_store", insrc, outsrc, 3, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS 2:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    if (SPECT_OP_DATA_OUT_SIZE != 1):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
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
        print("SPECT_OP_STATUS 3:", SPECT_OP_STATUS)
        tc.print_failed()
        sys.exit(1)

    if (SPECT_OP_DATA_OUT_SIZE != 80):
        print("SPECT_OP_DATA_OUT_SIZE:", SPECT_OP_DATA_OUT_SIZE)
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

    if key_store(test_dir, run_name, slot, k) == 1: sys.exit(1)

    sign1 = ecdsa_sign(test_dir, run_name, keymem, slot, sch, scn, z)
    if sign1 == None: sys.exit(1)
    if sign1 != sign_ref:
        print("Signature 1 fail")
        tc.print_failed()
        sys.exit(1)

    sign2 = ecdsa_sign(test_dir, run_name, keymem, slot, sch, scn, z)
    if sign2 == None: sys.exit(1)
    if sign2 != sign_ref:
        print("Signature 2 fail")
        tc.print_failed()
        sys.exit(1)

    A = key_read(test_dir, run_name, keymem, slot)
    if A == None: sys.exit(1)
    if A != A_ref:
        print("Pub key 2 fail")
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

    sys.exit(0)
