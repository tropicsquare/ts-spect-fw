#!/usr/bin/env python3
import sys
import random as rn
from enum import Enum

from import_setup import import_setup
import_setup()

import models.p256 as p256

from spect_tester.spect_tester import SpectTester, SpectTestRun
from spect_tester.spect_memory import SpectMem
from spect_tester.spect_config import (
    SpectOpStatus,
    L3Result,
    KeyTypes,
    CurveType,
    EccSlot
)
from spect_tester.helpers import (
    random_bytes,
    get_main_defines,
    create_metadata,
    int2bytes,
    get_input_source,
    get_output_source,
)
from spect_tester.spect_default_fw import (
    SpectDefaultFW
)

SPECT_FW = SpectDefaultFW.Application
defines_set = get_main_defines(SPECT_FW.s_file)

class TestType(Enum):
    OK = 0
    EMPTY_SLOT = 1
    INVALID_CURVE = 2
    INVALID_SLOT_NUMBER = 3

def test_run(tester: SpectTester, test_type: TestType):

    run_name = f"ecdsa_sign_{test_type.name.lower()}"

    test_run = tester.create_test_run(run_name)
    test_run.cmd_start()

    test_run.set_op("ecdsa_sign")

    test_run.set_rng()

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

    metadata_curve = CurveType.P256
    metadata_slot = slot

    if test_type == TestType.INVALID_CURVE:
        metadata_curve = CurveType.ED25519
    if test_type == TestType.INVALID_SLOT_NUMBER:
        metadata_slot = slot+1

    pub_metadata_ref, priv_metadata_ref = create_metadata(
        curve   = metadata_curve,
        slot    = metadata_slot,
        origin  = 0x1
    )

    d, w, Ax, Ay = p256.key_gen(random_bytes(32))
    sch = random_bytes(32)
    scn = random_bytes(4)
    z   = random_bytes(32)

    r_ref, s_ref = p256.sign(d, w, sch, scn, z)
    signature_ref = int2bytes(r_ref, endianity='big') + int2bytes(s_ref, endianity='big')
    test_run.info(f"Signature ref: {signature_ref.hex()}")

    wmask = rn.randint(0, 2**256 - 1)
    w = w ^ wmask
    d2 = rn.randint(0, p256.q)
    d1 = (d - d2) % p256.q

    pub = int2bytes(Ax) + int2bytes(Ay)

    if test_type != TestType.EMPTY_SLOT:
        test_run.set_key(priv_metadata_ref, KeyTypes.ECC, priv_slot, EccSlot.METADATA_OFFSET)
        test_run.set_key(pub_metadata_ref,  KeyTypes.ECC, pub_slot,  EccSlot.METADATA_OFFSET)

        test_run.set_key(int2bytes(d1),    KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k1'])
        test_run.set_key(int2bytes(w),     KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k2'])
        test_run.set_key(int2bytes(d2),    KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k3'])
        test_run.set_key(int2bytes(wmask), KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k4'])

        test_run.set_key(pub, KeyTypes.ECC, pub_slot, EccSlot.PUB_OFFSET)

    if test_type == TestType.EMPTY_SLOT:
        spect_status_ref = SpectOpStatus.RET_KEY_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY
    elif test_type == TestType.INVALID_CURVE:
        spect_status_ref = SpectOpStatus.RET_CURVE_TYPE_ERR
        l3_result_ref = L3Result.L3_RESULT_INVALID_KEY
    elif test_type == TestType.INVALID_SLOT_NUMBER:
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

    test_run.write_bytes(input_mem.base+0x10, z)
    test_run.write_bytes(SpectMem.DataRamIn.base + 0xA0, sch)
    test_run.write_bytes(SpectMem.DataRamIn.base + 0xC0, scn)

    test_run.set_input_size(32)

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

    # If error run, end
    if test_type != TestType.OK:
        test_run.status_summary()
        if test_run.err_cnt == 0:
            SpectTester.print_passed()
        else:
            SpectTester.print_failed()

        return test_run.err_cnt

    # Check output
    if data_out_size != 80:
        test_run.error(f"Invalid output size {data_out_size}")

    signature = test_run.read_bytes(output_mem.base+0x10, 64)
    test_run.info(f"Signature: {signature.hex()}")

    if signature != signature_ref:
        test_run.error(f"Invalid signature")

    test_run.status_summary()
    if test_run.err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    return test_run.err_cnt

if __name__ == "__main__":
    test_name = "ecdsa_sign"
    tester = SpectTester(test_name)

    test_run(tester, TestType.OK)
    test_run(tester, TestType.EMPTY_SLOT)
    test_run(tester, TestType.INVALID_CURVE)
    test_run(tester, TestType.INVALID_SLOT_NUMBER)

    err_cnt = tester.count_errors()

    sys.exit(err_cnt)
