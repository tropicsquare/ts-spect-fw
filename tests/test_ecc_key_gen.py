#!/usr/bin/env python3
import sys
import random as rn

import test_common as tc

import models.ed25519 as ed25519
import models.p256 as p256

Ed25519_ID = 0x02
P256_ID = 0x01

def test_process(test_dir, run_id, insrc, outsrc, key_type):
    cmd_file = tc.get_cmd_file(test_dir)

    run_name = f"ecc_key_gen_{run_id}"

    print("\033[94m{}\033[00m".format(f"running {run_name}"))

    rng = [rn.randint(0, 2**256-1) for i in range(8)]
    tc.set_rng(test_dir, rng)

    k = rng[0].to_bytes(32, 'little')
    print("privkey bytes", k.hex())

    slot = rn.randint(0, 7)
    print("slot:", slot)

    if key_type == Ed25519_ID:
        priv1_ref, priv2_ref = ed25519.secret_expand(k)
        pub1_ref = ed25519.secret_to_public(k)
        pub2_ref = 0
        print("s:       ", hex(priv1_ref))
        print("prefix:  ", priv2_ref.hex())
        print("A:       ", pub1_ref.hex())
    else:
        priv1_ref, priv2_ref, pub1_ref, pub2_ref = p256.key_gen(k)
        print("d:   ", hex(priv1_ref))
        print("w:   ", priv2_ref.hex())
        print("Ax:  ", hex(pub1_ref))
        print("Ay:  ", hex(pub2_ref))

    tc.start(cmd_file)

    input_word = (key_type << 16) + (slot << 8) + tc.find_in_list("ecc_key_gen", ops_cfg)["id"]
    print(hex(input_word))

    tc.write_int32(cmd_file, input_word, (insrc<<12))

    ctx = tc.run_op(cmd_file, "ecc_key_gen", insrc, outsrc, 3, ops_cfg, test_dir, run_id=run_id)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, run_name)

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        return 1

    priv1 = tc.get_key(type=0x04, slot=(slot<<1), offset=0)
    priv2 = tc.get_key(type=0x04, slot=slot, offset=8)
    pub1 = tc.get_key(type=0x04, slot=(slot<<1)+1, offset=8)
    pub2 = pub2_ref
    if key_type == P256_ID:
        pub2 = tc.get_key(type=0x04, slot=(slot<<1)+1, offset=16)

    curve = tc.get_key(type=0x04, slot=(slot<<1)+1, offset=0)

    l3_result = tc.read_output(test_dir, run_name, (outsrc << 12), 1)
    l3_result &= 0xFF

    if (l3_result != 0xc3):
        print("L3 RESULT:", hex(l3_result))
        return 1

    #if (not(
    #    priv1 == priv1_ref and
    #    priv2 == priv2_ref and
    #    pub1 == pub1_ref and
    #    pub2 == pub2_ref and
    #    curve==key_type)
    #):
    #    return 1

    return 0

if __name__ == "__main__":
    ops_cfg = tc.get_ops_config()
    test_name = "ecc_key_gen"

    test_dir = tc.make_test_dir(test_name)

# ===================================================================================
#   Curve = Ed25519, DATA RAM IN / OUT
# ===================================================================================
    if (test_process(test_dir, 0, 0x0, 0x1, Ed25519_ID)):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

# ===================================================================================
#   Curve = Ed25519, Command Buffer / Result Buffer
# ===================================================================================
    if (test_process(test_dir, 1, 0x4, 0x5, Ed25519_ID)):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

# ===================================================================================
#   Curve = P256, DATA RAM IN / OUT
# ===================================================================================
    if (test_process(test_dir, 2, 0x0, 0x1, P256_ID)):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

# ===================================================================================
#   Curve = P 256, Command Buffer / Result Buffer
# ===================================================================================
    if (test_process(test_dir, 3, 0x4, 0x5, P256_ID)):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()
    sys.exit(0)