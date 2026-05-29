#!/usr/bin/env python3
import sys
import random as rn
from enum import Enum
from dataclasses import dataclass

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
    KeyOrigin
)
from spect_tester.helpers import (
    SlotMetadataErrType,
    random_bytes,
    get_main_defines,
    create_metadata,
    get_input_source,
    get_output_source,
)

SPECT_FW = Application
defines_set = get_main_defines(SPECT_FW.s_file)

@dataclass
class ECC_KEY_READ_TEST_VEC:
    curve_type          : CurveType
    origin              : KeyOrigin
    metadata_error      : SlotMetadataErrType
    slot_is_populated   : bool
    pub_is_valid        : bool

# TEST VECTORS
class TEST_VEC:
#       Curve Type         Key Origin          Metadata corruption              populated  valid pub
# OK tests
    Ed25519_OK = ECC_KEY_READ_TEST_VEC(
        CurveType.ED25519, KeyOrigin.GENERATE, SlotMetadataErrType.NO_ERR,      True,      True
    )
    P256_OK = ECC_KEY_READ_TEST_VEC(
        CurveType.P256,    KeyOrigin.STORE,    SlotMetadataErrType.NO_ERR,      True,      True
    )
# Err tests
    EmptySlot = ECC_KEY_READ_TEST_VEC(
        CurveType.ED25519, KeyOrigin.GENERATE, SlotMetadataErrType.NO_ERR,      False,     True
    )
    Ed25519_InvalidPub = ECC_KEY_READ_TEST_VEC(
        CurveType.ED25519, KeyOrigin.GENERATE, SlotMetadataErrType.NO_ERR,      True,      False
    )
    P256_InvalidPub = ECC_KEY_READ_TEST_VEC(
        CurveType.P256,    KeyOrigin.GENERATE, SlotMetadataErrType.NO_ERR,      True,      False
    )
    MetadataErr_CurveType = ECC_KEY_READ_TEST_VEC(
        CurveType.ED25519, KeyOrigin.GENERATE, SlotMetadataErrType.CURVE_ERR,   True,      True
    )
    MetadataErr_SlotType = ECC_KEY_READ_TEST_VEC(
        CurveType.ED25519, KeyOrigin.GENERATE, SlotMetadataErrType.TYPE_ERR,    True,      True
    )
    MetadataErr_SlotNumber = ECC_KEY_READ_TEST_VEC(
        CurveType.ED25519, KeyOrigin.GENERATE, SlotMetadataErrType.NUMBER_ERR,  True,      True
    )
    MetadataErr_KeyOrigin = ECC_KEY_READ_TEST_VEC(
        CurveType.ED25519, KeyOrigin.GENERATE, SlotMetadataErrType.ORIGIN_ERR,  True,      True
    )

def _get_invalid_pub(curve: CurveType) -> bytes:
    valid = True
    if curve == CurveType.ED25519:
        while valid:
            pub = EdDSA.KeyGen()
            # Randomly alter the y ccordinate
            pub.P.y += rn.randint(0, 2**256)
            valid = Ed25519.from_bytes(pub.PublicBytes()).is_valid()
    elif curve == CurveType.P256:
        while valid:
            pub = ECDSA.KeyGen()
            # Randomly alter the y and x ccordinates
            pub.P.x += rn.randint(0, 2**256)
            pub.P.y += rn.randint(0, 2**256)
            valid = secp256r1.from_bytes(pub.PublicBytes()).is_valid()
    else:
        test_run.critical(f"Invalid CurveType value: {curve}")
        # critical exits

    return pub

def test_run(
    tester: SpectTester, test_vec: ECC_KEY_READ_TEST_VEC):

    if test_vec.slot_is_populated == False:
        suffix = "empty_slot"
    elif test_vec.pub_is_valid == False:
        suffix = "invalid_pub"
    elif test_vec.metadata_error != SlotMetadataErrType.NO_ERR:
        suffix = test_vec.metadata_error.name.lower()
    else:
        suffix = "ok"

    run_name = f"ecc_key_read_{test_vec.curve_type.name.lower()}_{suffix}"

    test_run = tester.create_test_run(run_name)
    test_run.cmd_start()

    test_run.set_op("ecc_key_read")

    ################################################################################################
    #   Set Input and Output source
    ################################################################################################
    input_mem = get_input_source(defines_set)
    output_mem = get_output_source(defines_set)

    test_run.set_input_source(input_mem.src)
    test_run.set_output_source(output_mem.src)

    ################################################################################################
    #   Create test vector and populate KeySlot
    ################################################################################################
    slot = rn.randint(0, 31)
    priv_slot = (slot << 1)
    pub_slot = (slot << 1)+1

    if test_vec.curve_type == CurveType.ED25519:
        pub_size = 32
        pub_ref = EdDSA.KeyGen(random_bytes(32))
    elif test_vec.curve_type == CurveType.P256:
        pub_size = 64
        pub_ref = ECDSA.KeyGen(random_bytes(32))
    else:
        test_run.critical(f"Invalid CurveType value: {test_vec.curve_type}")
        # critical exits

    if test_vec.pub_is_valid == False:
        pub_ref = _get_invalid_pub(test_vec.curve_type)

    pub_ref_in_slot = pub_ref.PublicBytes(encoding="spect")
    pub_ref = pub_ref.PublicBytes() # Get the pub in default encoding

    privs = random_bytes(4*32)

    pub_metadata_ref, priv_metadata_ref = create_metadata(
        curve            = test_vec.curve_type,
        slot             = slot,
        origin           = test_vec.origin,
        invalid_metadata = test_vec.metadata_error
    )

    # Populate slot
    if test_vec.slot_is_populated == True:
        test_run.info(f"Pubkey Ref: {pub_ref.hex()}")
        test_run.set_key(privs, KeyTypes.ECC, priv_slot, 0)
        test_run.set_key(priv_metadata_ref, KeyTypes.ECC, priv_slot, EccSlot.METADATA_OFFSET)

        test_run.set_key(pub_ref_in_slot, KeyTypes.ECC, pub_slot, EccSlot.PUB_OFFSET)
        test_run.set_key(pub_metadata_ref, KeyTypes.ECC, pub_slot, EccSlot.METADATA_OFFSET)

    # Predict SPECT response
    if test_vec.slot_is_populated == False:                         # Empty slot
        spect_status_ref = SpectOpStatus.RET_KEY_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY

    elif test_vec.pub_is_valid == False:                            # Invalid Pub
        spect_status_ref = SpectOpStatus.RET_KEY_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY

    elif test_vec.metadata_error == SlotMetadataErrType.CURVE_ERR:  # Invalid Curve Type
        spect_status_ref = SpectOpStatus.RET_CURVE_TYPE_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY

    elif test_vec.metadata_error != SlotMetadataErrType.NO_ERR:     # Other error in metadata
        spect_status_ref = SpectOpStatus.RET_SLOT_METADATA_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY

    else:                                                           # Everithing OK
        spect_status_ref = SpectOpStatus.RET_OP_SUCCESS
        l3_result_ref = L3Result.L3_RESULT_OK

    ################################################################################################
    #   Write data and launch
    ################################################################################################
    l3_input_word = (slot << 8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    test_run.set_input_size(0)

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

    # If some error, end
    if ((test_vec.slot_is_populated == False) or
        (test_vec.pub_is_valid == False) or
        (test_vec.metadata_error != SlotMetadataErrType.NO_ERR)
    ):
        test_run.status_summary()
        if test_run.err_cnt == 0:
            SpectTester.print_passed()
        else:
            SpectTester.print_failed()

        return test_run.err_cnt

    # Check output
    if data_out_size != pub_size + 16:
        test_run.error(f"Invalid output size")

    r_curve = (l3_result_word >> 8) & 0xFF
    r_origin = (l3_result_word >> 16) & 0xFF

    if r_curve != test_vec.curve_type:
        test_run.error(f"Invalid curve type")

    if r_origin != test_vec.origin:
        test_run.error(f"Invalid key origin")

    test_run.info(f"Pub Size: {pub_size}")
    r_pub = test_run.read_bytes(output_mem.base+0x10, pub_size)
    test_run.info(f"Len: {len(r_pub)}")

    test_run.info(f"Pubkey: {r_pub.hex()}")

    if r_pub != pub_ref:
        test_run.error(f"Invalid Pub key returned")

    test_run.status_summary()
    if test_run.err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    return test_run.err_cnt

if __name__ == "__main__":
    test_name = "ecc_key_read"
    tester = SpectTester(test_name, spect_fw=Application)

    # No Error
    test_run(tester, TEST_VEC.Ed25519_OK                )
    test_run(tester, TEST_VEC.P256_OK                   )
    # Empty Slot
    test_run(tester, TEST_VEC.EmptySlot                 )
    # Invalid ECC Pub key
    test_run(tester, TEST_VEC.Ed25519_InvalidPub        )
    test_run(tester, TEST_VEC.P256_InvalidPub           )
    # Invalid Slot metadata
    test_run(tester, TEST_VEC.MetadataErr_CurveType     )
    test_run(tester, TEST_VEC.MetadataErr_SlotType      )
    test_run(tester, TEST_VEC.MetadataErr_SlotNumber    )
    test_run(tester, TEST_VEC.MetadataErr_KeyOrigin     )

    err_cnt = tester.count_errors()

    sys.exit(err_cnt)
