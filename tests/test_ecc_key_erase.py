#!/usr/bin/env python3
import sys
import random as rn

from default_fw import Application

from import_setup import import_setup
import_setup()

from spect_tester.spect_tester import SpectTester, SpectTestRun
from spect_tester.key_memory import KeyMem
from spect_tester.spect_config import (
    SpectOpStatus,
    L3Result,
    KeyTypes
)
from spect_tester.helpers import (
    random_bytes,
    get_main_defines,
    get_input_source,
    get_output_source,
)

TEST_FULL_SLOT = "full_slot"
TEST_EMPTY_SLOT = "empty_slot"

SPECT_FW = Application
defines_set = get_main_defines(SPECT_FW.s_file)

def test_run(tester: SpectTester, run_name: str):
    test_run = tester.create_test_run(run_name)
    test_run.cmd_start()

    test_run.set_op("ecc_key_erase")

    ################################################################################################
    #   Set Input and Output source
    ################################################################################################
    input_mem = get_input_source(defines_set)
    output_mem = get_output_source(defines_set)

    test_run.set_input_source(input_mem.src)
    test_run.set_output_source(output_mem.src)

    slot = rn.randint(0, 127)
    priv_slot = (slot << 1)
    pub_slot = (slot << 1)+1

    if run_name.endswith(TEST_FULL_SLOT):
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

    l3_input_word = (slot<<8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    test_run.set_input_size(0)

    test_run.run()

    status, data_out_size = test_run.get_res_word()
    test_run.info(f"SPECT Status: 0x{status:02x}")
    test_run.info(f"SPECT OutSize: {data_out_size}")

    if status != SpectOpStatus.RET_OP_SUCCESS:
        test_run.error(f"Invalid SPECT Op Status")

    l3_result_word = test_run.read_word(output_mem.base)
    assert l3_result_word is not None
    l3_result = l3_result_word & 0xFF

    if l3_result != L3Result.L3_RESULT_OK:
        test_run.error(f"Invalid L3 Result")

    if test_run.key_slot_status(KeyTypes.ECC, priv_slot) != KeyMem.SlotStatus.EMPTY:
        test_run.error(f"Private Key Slot status is not EMPTY")

    if test_run.key_slot_status(KeyTypes.ECC, pub_slot) != KeyMem.SlotStatus.EMPTY:
        test_run.error(f"Public Key Slot status is not EMPTY")

    test_run.status_summary()

    if test_run.err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

if __name__ == "__main__":
    test_name = "ecc_key_erase"
    tester = SpectTester(test_name, spect_fw=Application)

    test_run(tester, f"{test_name}_{TEST_FULL_SLOT}")
    test_run(tester, f"{test_name}_{TEST_EMPTY_SLOT}")

    err_cnt = tester.count_errors()

    sys.exit(err_cnt)
