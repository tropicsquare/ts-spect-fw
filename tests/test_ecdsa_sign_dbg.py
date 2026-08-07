#!/usr/bin/env python3
import sys
import random as rn
from enum import Enum

from default_fw import Application

from import_setup import import_setup
import_setup()

from spect_models.ECDSA import ECDSA_SECP256R1 as ECDSA
from spect_models.Curves.secp256r1 import secp256r1
from spect_models.Fields.Field_secp256r1 import Field

from spect_tester.spect_tester import SpectTester
from spect_tester.spect_memory import SpectMem
from spect_tester.spect_config import (
    SpectOpStatus,
    L3Result,
)
from spect_tester.helpers import (
    random_bytes,
    get_main_defines,
    int2bytes,
)

SPECT_FW = Application
defines_set = get_main_defines(SPECT_FW.s_file)

class TestType(Enum):
    OK = 0
    EMPTY_SLOT = 1
    INVALID_CURVE = 2
    INVALID_SLOT_NUMBER = 3

def test_run(tester: SpectTester):

    run_name = f"ecdsa_sign_dbg"

    test_run = tester.create_test_run(run_name)
    test_run.cmd_start()

    test_run.set_op("ecdsa_sign_dbg")

    test_run.set_rng()

    ################################################################################################
    #   Set Input and Output source
    ################################################################################################
    test_run.set_input_source(SpectMem.DataRamIn.src)
    test_run.set_output_source(SpectMem.DataRamOut.src)

    ################################################################################################
    #   Create test vector and populate KeySlot
    ################################################################################################
    key = ECDSA.KeyGen()
    sch = random_bytes(32)
    scn = random_bytes(4)
    z   = random_bytes(32)

    signature_ref = ECDSA.Sign(M=z, Key=key, sch=sch, scn=scn)
    test_run.info(f"Signature ref: {signature_ref.to_bytes().hex()}")

    tester.info(f"Pub ref: {key.PublicBytes().hex()}")
    tester.info(f"Signature ref: {signature_ref.to_bytes().hex()}")

    test_run.write_bytes(SpectMem.DataRamIn.base+0x040, int2bytes(key.d))
    test_run.write_bytes(SpectMem.DataRamIn.base+0x060, int2bytes(key.w))
    test_run.write_bytes(SpectMem.DataRamIn.base+0x160, key.PublicBytes(encoding='spect'))

    ################################################################################################
    #   Write data and launch
    ################################################################################################
    test_run.write_bytes(SpectMem.DataRamIn.base+0x10, z)
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

    if status != SpectOpStatus.RET_OP_SUCCESS:
        test_run.error(
            f"Invalid SPECT Op Status\n"+
            f"\tExpected {SpectOpStatus.RET_OP_SUCCESS:02x}\n"+
            f"\tObserved {status:02x}"
        )

    l3_result_word = test_run.read_word(SpectMem.DataRamOut.base)
    assert l3_result_word is not None
    l3_result = l3_result_word & 0xFF

    if l3_result != L3Result.L3_RESULT_OK:
        test_run.error(
            f"Invalid L3 Result\n"+
            f"\tExpected {L3Result.L3_RESULT_OK:02x}\n"+
            f"\tObserved {l3_result:02x}"
        )

    # Check output
    if data_out_size != 80:
        test_run.error(f"Invalid output size {data_out_size}")

    signature = test_run.read_bytes(SpectMem.DataRamOut.base+0x10, 64)
    test_run.info(f"Signature: {signature.hex()}")

    if signature != signature_ref.to_bytes():
        test_run.error(f"Invalid signature")

    test_run.status_summary()
    if test_run.err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    return test_run.err_cnt

if __name__ == "__main__":
    tester = SpectTester("ecdsa_sign_dbg", spect_fw=Application)

    if "DEBUG_OPS" not in defines_set:
        SpectTester.print_test_skipped("Debug ops are disabled")
        sys.exit(0)

    test_run(tester)

    sys.exit(tester.err_cnt)
