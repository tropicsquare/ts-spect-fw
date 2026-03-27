#!/usr/bin/env python3
import sys
import random as rn
import itertools

import hashlib

from default_fw import Application

from import_setup import import_setup
import_setup()

from spect_models.ECDSA import ECDSA_SECP256R1 as ECDSA
from spect_models.Curves.secp256r1 import secp256r1
from spect_models.Fields.Field_secp256r1 import Field

from spect_models.EdDSA import EdDSA
from spect_models.Curves.Ed25519 import Ed25519
from spect_models.Fields.Field255 import Field

from spect_tester.spect_tester import SpectTester, SpectTestRun
from spect_tester.spect_config import (
    SpectOpStatus,
    L3Result,
    KeyTypes,
    CurveType,
    EccSlot,
    KeyOrigin,
)
from spect_tester.key_memory import KeyMem
from spect_tester.helpers import (
    random_bytes,
    get_main_defines,
    create_metadata,
    int2bytes,
    bytes2int,
    get_input_source,
    get_output_source,
)

ECC_KEY_ORIGIN = {
    "ecc_key_gen"   : KeyOrigin.GENERATE,
    "ecc_key_store" : KeyOrigin.STORE
}

SPECT_FW = Application
defines_set = get_main_defines(SPECT_FW.s_file)

TEST_GENERATE = "ecc_key_gen"
TEST_STORE = "ecc_key_store"

TEST_FULL_SLOT = "full_slot"
TEST_EMPTY_SLOT = "empty_slot"

def __get_p256_keys(k: bytes):
    Key = ECDSA.KeyGen(k)
    k1 = int2bytes(Key.d)
    k2 = int2bytes(Key.w)
    pub = Key.PublicBytes(encoding="spect")
    return k1, k2, pub

def __get_ed25519_keys(k: bytes):
    Key = EdDSA.KeyGen(k)
    k1 = int2bytes(Key.s)
    k2 = int2bytes(Key.prefix)
    pub = Key.PublicBytes(encoding="spect")
    return k1, k2, pub

def __unmask_privs(k1_1: bytes, k1_2: bytes, k2_1: bytes, k2_2: bytes, curve_type: CurveType):
    if curve_type == CurveType.ED25519:
        mod = Ed25519.Q
    else:
        mod = secp256r1.Q

    k1 = int2bytes((bytes2int(k1_1) + bytes2int(k1_2)) % mod)
    k2 = bytes(x ^ y for x, y in zip(k2_1, k2_2))

    return k1, k2

def test_run(tester: SpectTester, op_name: str, curve_type: CurveType, slot_state: str):

    run_name = f"{op_name}_{curve_type.name.lower()}_{slot_state}"

    test_run = tester.create_test_run(run_name)
    test_run.cmd_start()

    test_run.set_op(op_name)

    ################################################################################################
    #   Set Input and Output source
    ################################################################################################
    input_mem = get_input_source(defines_set)
    output_mem = get_output_source(defines_set)

    test_run.set_input_source(input_mem.src)
    test_run.set_output_source(output_mem.src)

    ################################################################################################
    #   Set RNG
    ################################################################################################
    rng = [rn.randint(1, 2**256-1) for _ in range(10)]
    test_run.set_rng(rng)

    ################################################################################################
    #   Create test vector
    ################################################################################################
    slot = rn.randint(0, 31)
    priv_slot = (slot << 1)
    pub_slot = (slot << 1)+1

    if curve_type == CurveType.ED25519:
        if op_name == TEST_GENERATE:
            rng0 = rng[0].to_bytes(32, byteorder='big')
            rng1 = rng[1].to_bytes(32, byteorder='big')
            k_wide = hashlib.sha512(rng0 + rng1).digest()
            k = bytes([a ^ b for a, b in zip(k_wide[:32], k_wide[32:])])[::-1]
        else:
            k = random_bytes(32)
        priv1_ref, priv2_ref, pub_ref = __get_ed25519_keys(k)
        pub_size = 32

    elif curve_type == CurveType.P256:
        if op_name == TEST_GENERATE:
            k = int2bytes(((rng[1]<<256) + (rng[0])) % secp256r1.Q, endianity='big')
        else:
            k = int2bytes(rn.randint(1, secp256r1.Q -1))
        priv1_ref, priv2_ref, pub_ref = __get_p256_keys(k)
        pub_size = 64

    test_run.info(f"k: {k.hex()}")

    test_run.info(f"Priv1 ref: {priv1_ref.hex()}")
    test_run.info(f"Priv2 ref: {priv2_ref.hex()}")
    test_run.info(f"Pub ref:   {pub_ref.hex()}")

    pub_metadata_ref, priv_metadata_ref = create_metadata(
        curve   = curve_type,
        slot    = slot,
        origin  = ECC_KEY_ORIGIN[op_name]
    )

    test_run.info(f"Priv Metadata ref: {priv_metadata_ref.hex()}")
    test_run.info(f"Pub Metadata ref:  {pub_metadata_ref.hex()}")

    if slot_state == TEST_FULL_SLOT:
        spect_status_ref = SpectOpStatus.RET_KEY_ERR
        l3_result_ref = L3Result.L3_RESULT_FAIL
    elif curve_type == CurveType.INVALID:
        spect_status_ref = SpectOpStatus.RET_CURVE_TYPE_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY
    else:
        spect_status_ref = SpectOpStatus.RET_OP_SUCCESS
        l3_result_ref = L3Result.L3_RESULT_OK

    ################################################################################################
    #   Write data and launch
    ################################################################################################
    l3_input_word = (curve_type << 24) + (slot << 8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    if op_name == TEST_GENERATE:
        test_run.set_input_size(0)
    else:
        test_run.set_input_size(32)

    if op_name == TEST_STORE:
        test_run.write_bytes(input_mem.base+0x10, k)

    if slot_state == TEST_FULL_SLOT:
        test_run.set_key(
            key     = random_bytes(32),
            ktype   = KeyTypes.ECC,
            slot    = priv_slot,
            offset  = 0
        )
        test_run.set_key(
            key     = random_bytes(32),
            ktype   = KeyTypes.ECC,
            slot    = pub_slot,
            offset  = 0
        )

    test_run.run()

    ################################################################################################
    #   Chech results
    ################################################################################################
    # check spect and l3 status
    status, data_out_size = test_run.get_res_word()
    test_run.info(f"SPECT Status: 0x{status:02x}")
    test_run.info(f"SPECT OutSize: {data_out_size}")

    if status != spect_status_ref:
        test_run.error(
            f"Invalid SPECT Op Status\n"+
            f"\tExpected {spect_status_ref:02x}\n"+
            f"\tObserved {status:02x}"
        )

    l3_result_word = test_run.read_word(output_mem.base)
    assert l3_result_word is not None
    l3_result = l3_result_word & 0xFF

    if l3_result != l3_result_ref:
        test_run.error(
            f"Invalid L3 Result\n"+
            f"\tExpected {l3_result_ref:02x}\n"+
            f"\tObserved {l3_result:02x}"
        )

    # If full slot or invalid curve, end
    if slot_state == TEST_FULL_SLOT or curve_type == CurveType.INVALID:
        test_run.status_summary()
        if test_run.err_cnt == 0:
            SpectTester.print_passed()
        else:
            SpectTester.print_failed()

        return test_run.err_cnt

    # Check slot states
    if test_run.key_slot_status(KeyTypes.ECC, priv_slot) != KeyMem.SlotStatus.FULL:
        test_run.error("Private slot not populated")
    if test_run.key_slot_status(KeyTypes.ECC, pub_slot) != KeyMem.SlotStatus.FULL:
        test_run.error("Public slot not populated")

    # Read and unmask private keys, check
    priv1 = test_run.read_key(KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k1'])
    priv2 = test_run.read_key(KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k2'])
    priv3 = test_run.read_key(KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k3'])
    priv4 = test_run.read_key(KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k4'])
    priv_metadata = test_run.read_key(KeyTypes.ECC, priv_slot, EccSlot.METADATA_OFFSET, size=4)

    priv1, priv2 = __unmask_privs(priv1, priv3, priv2, priv4, curve_type)

    test_run.info(f"Priv1: {priv1.hex()}")
    test_run.info(f"Priv2: {priv2.hex()}")
    test_run.info(f"Priv Metadata: {priv_metadata_ref.hex()}")

    if priv1 != priv1_ref:
        test_run.error("Priv1 mismatch")
    if priv2 != priv2_ref:
        test_run.error("Priv2 mismatch")
    if priv_metadata != priv_metadata_ref:
        test_run.error("Priv metadata mismatch")

    # Read public key, check
    pub = test_run.read_key(KeyTypes.ECC, pub_slot, EccSlot.PUB_OFFSET, size=pub_size)
    pub_metadata = test_run.read_key(KeyTypes.ECC, pub_slot, EccSlot.METADATA_OFFSET, size = 4)

    test_run.info(f"Pub Metadata: {pub_metadata.hex()}")
    test_run.info(f"Pub: {pub.hex()}")

    if pub != pub_ref:
        test_run.error("Pub mismatch")
    if pub_metadata != pub_metadata_ref:
        test_run.error("Pub metadata mismatch")

    test_run.status_summary()

    # End
    if test_run.err_cnt == 0:
        test_run.info("Test PASSED")
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    return test_run.err_cnt

if __name__ == "__main__":
    test_name = "ecc_key_gen_store"
    tester = SpectTester(test_name, spect_fw=Application)

    test_vars = [
        [TEST_GENERATE,  TEST_STORE],           # op_name
        [CurveType.P256, CurveType.ED25519],    # curve type
        [TEST_FULL_SLOT, TEST_EMPTY_SLOT]       # slot state
    ]

    for test_comb in list(itertools.product(*test_vars)):
        test_run(
            tester,
            op_name     = test_comb[0],
            curve_type  = test_comb[1],
            slot_state  = test_comb[2]
        )

    err_cnt = tester.count_errors()

    sys.exit(err_cnt)
