#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc

import models.ed25519 as ed25519
import models.p256 as p256

def test_process(test_dir, run_id, insrc, outsrc, key_type):
    cmd_file = tc.get_cmd_file(test_dir)

    rng = [rn.randint(0, 2**256-1) for i in range(8)]
    tc.set_rng(test_dir, rng)

    k = rng[0].to_bytes(32, 'little')

    slot = rn.randint(0, 7)

    run_name = f"ecc_key_gen_{run_id}_{slot}"

    tc.print_run_name(run_name)

    if key_type == tc.Ed25519_ID:
        priv1_ref, priv2_ref = ed25519.secret_expand(k)
        pub1_ref = ed25519.secret_to_public(k)
        pub2_ref = 0
        priv2_ref = int.from_bytes(priv2_ref, 'big')
        pub1_ref = int.from_bytes(pub1_ref, 'big')
        #print("s:       ", hex(priv1_ref))
        #print("prefix:  ", hex(priv2_ref))
        #print("A:       ", hex(pub1_ref))
    else:
        priv1_ref, priv2_ref, pub1_ref, pub2_ref = p256.key_gen(k)
        priv2_ref = int.from_bytes(priv2_ref, 'big')
        #print("d:   ", hex(priv1_ref))
        #print("w:   ", hex(priv2_ref))
        #print("Ax:  ", hex(pub1_ref))
        #print("Ay:  ", hex(pub2_ref))

    tc.start(cmd_file)

    input_word = (key_type << 16) + (slot << 8) + tc.find_in_list("ecc_key_gen", ops_cfg)["id"]

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ctx = tc.run_op(cmd_file, "ecc_key_gen", insrc, outsrc, 3, ops_cfg, test_dir, run_name=run_name)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    kmem_data, kmem_slots = tc.parse_key_mem(test_dir, run_name)

    if not kmem_slots[0x4][slot<<1]:
        print("Private Key Slot is empty.")
        return 1

    if not kmem_slots[0x4][(slot<<1)+1]:
        print("Public Key Slot is empty.")
        return 1

    priv1 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1), offset=0)
    priv2 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1), offset=8)
    pub1 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1)+1, offset=8)
    pub2 = pub2_ref
    if key_type == tc.P256_ID:
        pub2 = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1)+1, offset=16)

    metadata = tc.get_key(kmem_data, ktype=0x04, slot=(slot<<1)+1, offset=0)

    #print("Curve:  ", hex(metadata & 0xFF))
    #print("Origin: ", hex((metadata >> 8) & 0xFF))

    #print("priv1:    ", hex(priv1))
    #print("priv1_ref:", hex(priv1_ref))
    #print()
    #print("priv2:    ", hex(priv2))
    #print("priv2_ref:", hex(priv2_ref))
    #print()
    #print("pub1:     ", hex(pub1))
    #print("pub1_ref: ", hex(pub1_ref))
    #print()
    #print("pub2:     ", hex(pub2))
    #print("pub2_ref: ", hex(pub2_ref))
    #print()

    l3_result = tc.read_output(test_dir, run_name, (outsrc << 12), 1)
    l3_result &= 0xFF

    if (l3_result != 0xc3):
        print("L3 RESULT:", hex(l3_result))
        return 1

    if (not(
        priv1 == priv1_ref and
        priv2 == priv2_ref and
        pub1 == pub1_ref and
        pub2 == pub2_ref and
        metadata & 0xFF==key_type)
    ):
        return 1

    return 0

if __name__ == "__main__":

    ret = 0

    seed = rn.randint(0, 2**32-1)
    rn.seed(seed)
    print("seed:", seed)
    
    ops_cfg = tc.get_ops_config()
    test_name = "ecc_key_gen"

    test_dir = tc.make_test_dir(test_name)

# ===================================================================================
#   Curve = Ed25519, DATA RAM IN / OUT
# ===================================================================================
    if (test_process(test_dir, "ed25519_ram", 0x0, 0x1, tc.Ed25519_ID)):
        tc.print_failed()
        ret |= 1

    tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

# ===================================================================================
#   Curve = Ed25519, Command Buffer / Result Buffer
# ===================================================================================
    if (test_process(test_dir, "ed25519_cpb", 0x4, 0x5, tc.Ed25519_ID)):
        tc.print_failed()
        ret |= 2

    tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

# ===================================================================================
#   Curve = P256, DATA RAM IN / OUT
# ===================================================================================
    if (test_process(test_dir, "p256_ram", 0x0, 0x1, tc.P256_ID)):
        tc.print_failed()
        ret |= 4

    tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

# ===================================================================================
#   Curve = P 256, Command Buffer / Result Buffer
# ===================================================================================
    if (test_process(test_dir, "p256_cpb", 0x4, 0x5, tc.P256_ID)):
        tc.print_failed()
        ret |= 8

    tc.print_passed()

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm -r {test_dir}")

    sys.exit(ret)