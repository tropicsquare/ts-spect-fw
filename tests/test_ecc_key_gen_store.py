#!/usr/bin/env python3
import sys
import random as rn
import itertools

import test_common as tc

import models.ed25519 as ed25519
import models.p256 as p256

ecc_key_origin = {
    "ecc_key_gen" : 0x1,
    "ecc_key_store" : 0x2
}

defines_set = tc.get_main_defines()

def test_process(test_dir, run_id, insrc, outsrc, key_type, op, full_slot=False):

    cmd_file = tc.get_cmd_file(test_dir)

    rng = [rn.randint(1, 2**256-1) for _ in range(10)]
    tc.set_rng(test_dir, rng)

    k = rng[0].to_bytes(32, 'little')

    slot = rn.randint(0, 31)

    if full_slot:
        slot_state = "full_slot"
    else:
        slot_state = "empty_slot"

    run_name = f"{op}_{run_id}_{slot}_{slot_state}"

    tc.print_run_name(run_name)

    if "ram" in run_id and (
        ("IN_SRC_EN" not in defines_set) or ("OUT_SRC_EN" not in defines_set)
    ):
        tc.print_test_skipped("INOUT_SRC debug feature is disabled.")
        return 0

    if key_type == tc.Ed25519_ID:
        priv1_ref, priv2_ref = ed25519.secret_expand(k)
        pub1_ref = ed25519.secret_to_public(k)
        pub1_ref = int.from_bytes(pub1_ref, 'big')
        pub2_ref = 0
        priv1_ref = priv1_ref % ed25519.q
        priv2_ref = int.from_bytes(priv2_ref, 'big')
    else:
        if op == "ecc_key_gen":
            k = rng[1].to_bytes(32, 'big') + rng[0].to_bytes(32, 'big')
        else:
            k = (rng[0] % p256.q).to_bytes(32, 'little')
        priv1_ref, priv2_ref, pub1_ref, pub2_ref = p256.key_gen(k)
        priv2_ref = int.from_bytes(priv2_ref, 'big')

    tc.start(cmd_file)
    tc.gpr_preload(cmd_file)

    input_word = (key_type << 24) + (slot << 8) + tc.find_in_list(op, ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))
    if full_slot:
        tc.set_key(cmd_file, 0x1234, ktype=0x4, slot=slot*2, offset=0)

    if op == "ecc_key_store":
        tc.write_bytes(cmd_file, k, (insrc<<12) +  0x10)

    ctx = tc.run_op(cmd_file, op, insrc, outsrc, 3, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS and not full_slot):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    if (SPECT_OP_STATUS == 0 and full_slot):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    if (SPECT_OP_DATA_OUT_SIZE != 1):
        print("SPECT_OP_DATA_OUT_SIZE:", hex(SPECT_OP_DATA_OUT_SIZE))
        return 1

    kmem_data, kmem_slots = tc.parse_key_mem(test_dir, run_name)

    if not full_slot:
        if not kmem_slots[0x4][slot<<1]:
            print("Private Key Slot is empty.")
            return 1

        if not kmem_slots[0x4][(slot<<1)+1]:
            print("Public Key Slot is empty.")
            return 1

        priv1 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1), offset=0)
        priv2 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1), offset=8)
        priv3 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1), offset=16)
        priv4 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1), offset=24)

        if key_type == tc.Ed25519_ID:
            priv1 = (priv1 + priv3) % ed25519.q
        else:
            priv1 = (priv1 + priv3) % p256.q

        priv2 = priv2 ^ priv4

        pub1 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1)+1, offset=8)

        pub2 = pub2_ref
        if key_type == tc.P256_ID:
            pub2 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1)+1, offset=16)

        metadata = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1)+1, offset=0)
        key_type_observed = metadata & 0xFF
        origin_observed = (metadata >> 8) & 0xFF

        if not((
            priv1 == priv1_ref and
            priv2 == priv2_ref and
            pub1 == pub1_ref and
            pub2 == pub2_ref and
            key_type_observed == key_type and
            origin_observed == ecc_key_origin[op]
        )):
            print("Curve:  ", hex(metadata & 0xFF))
            print("Origin: ", hex((metadata >> 8) & 0xFF))
            print("priv1:    ", hex(priv1))
            print("priv1_ref:", hex(priv1_ref))
            print()
            print("priv2:    ", hex(priv2))
            print("priv2_ref:", hex(priv2_ref))
            print()
            print("priv3:    ", hex(priv3))
            print("priv4:    ", hex(priv4))
            print()
            print("pub1:     ", hex(pub1))
            print("pub1_ref: ", hex(pub1_ref))
            print()
            print("pub2:     ", hex(pub2))
            print("pub2_ref: ", hex(pub2_ref))
            print()
            return 1



    l3_result = tc.read_output(test_dir, run_name, (outsrc << 12), 1)
    l3_result &= 0xFF

    if (l3_result != 0xc3 and not full_slot):
        print("L3 RESULT:", hex(l3_result))
        return 1

    if (l3_result != 0x3c and full_slot):
        print("L3 RESULT:", hex(l3_result))
        return 1

    return 0

if __name__ == "__main__":

    ret = 0

    args = tc.parser.parse_args()
    seed = tc.set_seed(args)
    rn.seed(seed)
    print("seed:", seed)

    ops_cfg = tc.get_ops_config()
    test_name = "ecc_key_gen_store"

    test_dir = tc.make_test_dir(test_name)

    test_vars = [
        ["ecc_key_gen", "ecc_key_store"],
        [0x0, 0x4],
        [tc.Ed25519_ID, tc.P256_ID],
        [True, False]
    ]

    all_comb = list(itertools.product(*test_vars))
    fail_flag = 0

    src = {0x0: "ram", 0x4: "cpb"}
    curve_str = {tc.Ed25519_ID: "ed25519", tc.P256_ID: "p256"}

    for tst_comb in all_comb:
        op = tst_comb[0]
        insrc = tst_comb[1]
        outsrc = tst_comb[1]+1
        curve = tst_comb[2]
        full_slot = tst_comb[3]

        if (test_process(test_dir, f"{curve_str[curve]}_{src[insrc]}", insrc, outsrc, curve, op, full_slot)):
            tc.print_failed()
            fail_flag = fail_flag | 1
        else:
            tc.print_passed()

    sys.exit(fail_flag)
