#!/usr/bin/env python3
import sys
import random as rn
from typing import (
    Tuple,
    Type,
)

from default_fw import Application

from import_setup import import_setup
import_setup()

import models.ed25519 as ed25519

from spect_tester.spect_tester import SpectTester, SpectTestRun
from spect_tester.spect_memory import (
    MemorySpace,
    SpectMem,
)
from spect_tester.spect_config import (
    SpectOpStatus,
    L3Result,
    KeyTypes,
    CurveType,
    KeyOrigin,
)
from spect_tester.key_memory import KeyMem
from spect_tester.helpers import (
    random_bytes,
    get_main_defines,
    get_input_source,
    get_output_source,
)

from test_eddsa_sequence import eddsa_sign

SPECT_FW = Application
defines_set = get_main_defines(SPECT_FW.s_file)

def __check_status_ok(test_run: SpectTestRun, output_mem: Type[MemorySpace]):
    status, data_out_size = test_run.get_res_word()
    test_run.info(f"SPECT Status: 0x{status:02x}")
    test_run.info(f"SPECT OutSize: {data_out_size}")

    if status != SpectOpStatus.RET_OP_SUCCESS:
        test_run.error(
            f"Invalid SPECT Op Status\n"+
            f"\tExpected {SpectOpStatus.RET_OP_SUCCESS:02x}\n"+
            f"\tObserved {status:02x}"
        )

    l3_result_word = test_run.read_word(output_mem.base)
    assert l3_result_word is not None
    l3_result = l3_result_word & 0xFF

    if l3_result != L3Result.L3_RESULT_OK:
        test_run.error(
            f"Invalid L3 Result\n"+
            f"\tExpected {L3Result.L3_RESULT_OK:02x}\n"+
            f"\tObserved {l3_result:02x}"
        )

def store_eddsa_key(test_run: SpectTestRun, k: bytes, slot: int):
    test_run.cmd_start()
    test_run.set_op("ecc_key_store")
    test_run.set_rng()

    ################################################################################################
    #   Set Input and Output source
    ################################################################################################
    input_mem = get_input_source(defines_set)
    output_mem = get_output_source(defines_set)

    test_run.set_input_source(input_mem.src)
    test_run.set_output_source(output_mem.src)

    ################################################################################################
    #   Write data and launch
    ################################################################################################
    l3_input_word = (CurveType.ED25519 << 24) + (slot << 8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    test_run.set_input_size(32)

    test_run.write_bytes(input_mem.base+0x10, k)

    test_run.run()

    ################################################################################################
    #   Check Status
    ################################################################################################
    __check_status_ok(test_run, output_mem)

    # Check slot states
    if test_run.key_slot_status(KeyTypes.ECC, (slot<<1)) != KeyMem.SlotStatus.FULL:
        test_run.error("Private slot not populated")
    if test_run.key_slot_status(KeyTypes.ECC, (slot<<1)+1) != KeyMem.SlotStatus.FULL:
        test_run.error("Public slot not populated")

def read_eddsa_key(test_run: SpectTestRun, slot: int) -> Tuple[bytes, int, int]:
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
    #   Write data and launch
    ################################################################################################
    l3_input_word = (slot << 8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    test_run.set_input_size(32)

    test_run.run()

    ################################################################################################
    #   Check
    ################################################################################################
    __check_status_ok(test_run, output_mem)

    _, data_out_size = test_run.get_res_word()
    l3_result_word = test_run.read_word(output_mem.base)
    assert l3_result_word is not None

    pub = test_run.read_bytes(output_mem.base+0x10, data_out_size-16)
    curve = (l3_result_word >> 8) & 0xFF
    origin = (l3_result_word >> 16) & 0xFF

    return pub, curve, origin

if __name__ == "__main__":
    test_name = "eddsa_full_setup"
    tester = SpectTester(test_name, spect_fw=Application)

    ################################################################################################
    #   Generate Test Vector
    ################################################################################################
    slot = rn.randint(0,31)

    k = random_bytes(32)
    s, prefix, pub_ref = ed25519.key_gen(k)

    message = random_bytes(rn.randint(128, 256))
    sch = random_bytes(32)
    scn = random_bytes(4)

    signature_ref = ed25519.sign(s, prefix, pub_ref, sch, scn, message)

    ################################################################################################
    #   Store EdDSA Key
    ################################################################################################
    store_key_run_name = "key_store"
    store_key_run = tester.create_test_run(store_key_run_name)

    store_eddsa_key(store_key_run, k, slot)

    ################################################################################################
    #   EdDSA Sign
    ################################################################################################
    signature = eddsa_sign(
        tester,
        init_keymem_file    = store_key_run.keymem_file,
        message             = message,
        scn                 = scn,
        sch                 = sch,
        slot                = slot
    )

    if signature is not None:
        tester.info(f"Signature: {signature.hex()}")
        if signature != signature_ref:
            tester.error("Signature mismatch")
    else:
        tester.error("Signature is None")

    ################################################################################################
    #   Read EdDSA Key
    ################################################################################################
    read_key_run_name = "key_read"
    read_key_run = tester.create_test_run(read_key_run_name)
    read_key_run.set_input_keymem_file(store_key_run.keymem_file)

    pub, curve, origin = read_eddsa_key(read_key_run, slot)

    tester.info(f"Pub ref: {pub_ref.hex()}")
    tester.info(f"Pub:     {pub.hex()}")

    if pub != pub_ref:
        tester.error("Public key mismatch")

    if curve != CurveType.ED25519:
        tester.error("Curve type mismatch")

    if origin != KeyOrigin.STORE:
        tester.error("Key origin mismatch")

    ################################################################################################
    #   END Test
    ################################################################################################
    err_cnt = tester.count_errors()

    if err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    sys.exit(err_cnt)
