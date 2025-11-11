#!/usr/bin/env python3
import sys
import random as rn

from import_setup import import_setup
import_setup()

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
from spect_tester.spect_default_fw import (
    SpectDefaultFW
)

TEST_FULL_SLOT = "full_slot"
TEST_EMPTY_SLOT = "empty_slot"

SPECT_FW = SpectDefaultFW.Application
defines_set = get_main_defines(SPECT_FW.s_file)

def test_run(tester: SpectTester, curve_type: CurveType, origin: KeyOrigin, slot_state: str, invalid_metadata: SlotMetadataErrType):

    if slot_state == TEST_EMPTY_SLOT:
        suffix = TEST_EMPTY_SLOT
    elif invalid_metadata != SlotMetadataErrType.NO_ERR:
        suffix = invalid_metadata.name.lower()
    elif curve_type == CurveType.INVALID:
        suffix = "invalid_curve"
    else:
        suffix = "ok"

    run_name = f"ecc_key_read_{curve_type.name.lower()}_{suffix}"

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

    if curve_type == CurveType.ED25519:
        pub_size = 32
        pub_ref = random_bytes(pub_size)
        # Ed25519 Public is stored with swapped endianity for easier SPECT FW implementation
        pub_ref_in_slot = pub_ref[::-1]
    else:
        pub_size = 64
        pub_ref = random_bytes(pub_size)
        # P256 Public is stored with swapped endianity and coords for easier SPECT FW implementation
        pub_ref_in_slot = (pub_ref[:32])[::-1] + (pub_ref[32:])[::-1]

    privs = random_bytes(4*32)

    pub_metadata_ref, priv_metadata_ref = create_metadata(
        curve            = curve_type,
        slot             = slot,
        origin           = origin,
        invalid_metadata = invalid_metadata
    )

    if slot_state != TEST_EMPTY_SLOT:
        test_run.info(f"Pubkey Ref: {pub_ref.hex()}")
        test_run.set_key(privs, KeyTypes.ECC, priv_slot, 0)
        test_run.set_key(priv_metadata_ref, KeyTypes.ECC, priv_slot, EccSlot.METADATA_OFFSET)

        test_run.set_key(pub_ref_in_slot, KeyTypes.ECC, pub_slot, EccSlot.PUB_OFFSET)
        test_run.set_key(pub_metadata_ref, KeyTypes.ECC, pub_slot, EccSlot.METADATA_OFFSET)

    if slot_state == TEST_EMPTY_SLOT:
        spect_status_ref = SpectOpStatus.RET_KEY_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY
    elif curve_type == CurveType.INVALID:
        spect_status_ref = SpectOpStatus.RET_CURVE_TYPE_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY
    elif invalid_metadata == SlotMetadataErrType.CURVE_ERR:
        spect_status_ref = SpectOpStatus.RET_CURVE_TYPE_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY
    elif invalid_metadata != SlotMetadataErrType.NO_ERR:
        spect_status_ref = SpectOpStatus.RET_SLOT_METADATA_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY
    else:
        spect_status_ref = SpectOpStatus.RET_OP_SUCCESS
        l3_result_ref = L3Result.L3_RESULT_OK

    ################################################################################################
    #   Write data and launch
    ################################################################################################
    l3_input_word = (slot << 8) + test_run.op_dict['id']
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
    l3_result = l3_result_word & 0xFF

    if l3_result != l3_result_ref:
        test_run.error(
            f"Invalid L3 Result\n"+
            f"\tExpected {l3_result_ref:02x}\n"+
            f"\tObserved {l3_result:02x}"
        )

    # If some error, end
    if ((slot_state == TEST_EMPTY_SLOT) or
        (invalid_metadata != SlotMetadataErrType.NO_ERR) or
        (curve_type == CurveType.INVALID)
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

    if r_curve != curve_type:
        test_run.error(f"Invalid curve type")

    if r_origin != origin:
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
    tester = SpectTester(test_name)

    # No Error
    test_run(tester, CurveType.ED25519, KeyOrigin.GENERATE, TEST_FULL_SLOT, SlotMetadataErrType.NO_ERR)
    test_run(tester, CurveType.P256,    KeyOrigin.STORE,    TEST_FULL_SLOT, SlotMetadataErrType.NO_ERR)

    # Errors
    test_run(tester, CurveType.ED25519, KeyOrigin.GENERATE, TEST_EMPTY_SLOT, SlotMetadataErrType.NO_ERR)
    test_run(tester, CurveType.INVALID, KeyOrigin.GENERATE, TEST_FULL_SLOT,  SlotMetadataErrType.NO_ERR)
    test_run(tester, CurveType.ED25519, KeyOrigin.GENERATE, TEST_FULL_SLOT,  SlotMetadataErrType.CURVE_ERR)
    test_run(tester, CurveType.ED25519, KeyOrigin.GENERATE, TEST_FULL_SLOT,  SlotMetadataErrType.TYPE_ERR)
    test_run(tester, CurveType.ED25519, KeyOrigin.GENERATE, TEST_FULL_SLOT,  SlotMetadataErrType.NUMBER_ERR)
    test_run(tester, CurveType.ED25519, KeyOrigin.GENERATE, TEST_FULL_SLOT,  SlotMetadataErrType.ORIGIN_ERR)

    err_cnt = tester.count_errors()

    sys.exit(err_cnt)
