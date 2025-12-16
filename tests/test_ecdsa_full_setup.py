#!/usr/bin/env python3
import sys
import random as rn

from default_fw import Application

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
    KeyOrigin,
)
from spect_tester.key_memory import KeyMem
from spect_tester.helpers import (
    random_bytes,
    get_main_defines,
    int2bytes,
    get_input_source,
    get_output_source,
)

SPECT_FW = Application
defines_set = get_main_defines(SPECT_FW.s_file)

def store_ecdsa_key(test_run: SpectTestRun, k: bytes, slot: int):
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
    l3_input_word = (CurveType.P256 << 24) + (slot << 8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    test_run.set_input_size(32)

    test_run.write_bytes(input_mem.base+0x10, k)

    test_run.run()

    ################################################################################################
    #   Check Status
    ################################################################################################
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

    # Check slot states
    if test_run.key_slot_status(KeyTypes.ECC, (slot<<1)) != KeyMem.SlotStatus.FULL:
        test_run.error("Private slot not populated")
    if test_run.key_slot_status(KeyTypes.ECC, (slot<<1)+1) != KeyMem.SlotStatus.FULL:
        test_run.error("Public slot not populated")

    test_run.status_summary()

def ecdsa_sign(test_run: SpectTestRun, message: bytes, scn: bytes, sch: bytes, slot: int):
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
    #   Write data and launch
    ################################################################################################
    l3_input_word = (slot<<8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    test_run.write_bytes(input_mem.base+0x10, message)
    test_run.write_bytes(SpectMem.DataRamIn.base + 0xA0, sch)
    test_run.write_bytes(SpectMem.DataRamIn.base + 0xC0, scn)

    test_run.set_input_size(32)

    test_run.run()

    ################################################################################################
    #   Chech Status
    ################################################################################################
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

    signature = test_run.read_bytes(output_mem.base+0x10, 64)

    test_run.status_summary()

    return signature

def ecc_key_read(test_run: SpectTestRun, slot: int):
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
    l3_input_word = (slot<<8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    test_run.set_input_size(4)

    test_run.run()

    ################################################################################################
    #   Chech Status
    ################################################################################################
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

    curve = (l3_result_word >> 8) & 0xFF
    origin = (l3_result_word >> 16) & 0xFF

    pub = test_run.read_bytes(output_mem.base+0x10, data_out_size-16)

    return pub, curve, origin

if __name__ == "__main__":
    test_name = "ecdsa_full_setup"
    tester = SpectTester(test_name, spect_fw=Application)

    ################################################################################################
    #   Create Test Vector
    ################################################################################################
    k = random_bytes(32)
    slot = rn.randint(0,31)

    d, w, Ax, Ay = p256.key_gen(k)
    pub_ref = Ax.to_bytes(32, 'big') + Ay.to_bytes(32, 'big')

    sch = random_bytes(32)
    scn = random_bytes(4)
    msg = random_bytes(32)

    r_ref, s_ref = p256.sign(d, w, sch, scn, msg)
    signature_ref = int2bytes(r_ref, endianity='big') + int2bytes(s_ref, endianity='big')

    tester.info(f"K: {k.hex()}")
    tester.info(f"Pub ref: {pub_ref.hex()}")
    tester.info(f"Slot: {slot}")
    tester.info(f"Signature ref: {signature_ref.hex()}")

    ################################################################################################
    #   Store Key
    ################################################################################################
    key_store_run = tester.create_test_run("ecc_key_store_p256")
    store_ecdsa_key(key_store_run, k, slot)

    ################################################################################################
    #   ECDSA Sign
    ################################################################################################
    ecdsa_sign_run = tester.create_test_run("ecdsa_sign")
    ecdsa_sign_run.set_input_context_file(key_store_run.context_file)
    ecdsa_sign_run.set_input_keymem_file(key_store_run.keymem_file)
    signature = ecdsa_sign(ecdsa_sign_run, msg, scn, sch, slot)

    tester.info(f"Signature: {signature.hex()}")

    if signature != signature_ref:
        tester.error("Signature Mismatch")

    ################################################################################################
    #   ECC Key Read
    ################################################################################################
    ecc_key_read_run = tester.create_test_run("ecc_key_read")
    ecc_key_read_run.set_input_context_file(ecdsa_sign_run.context_file)
    ecc_key_read_run.set_input_keymem_file(ecdsa_sign_run.keymem_file)

    pub, curve, origin = ecc_key_read(ecc_key_read_run, slot)

    tester.info(f"Pub: {pub.hex()}")

    if pub != pub_ref:
        tester.error("Public Key Mismatch")

    if curve != CurveType.P256:
        tester.error("Curve Type Mismatch")

    if origin != KeyOrigin.STORE:
        tester.error("Key Origin Mismatch")

    ################################################################################################
    #   END
    ################################################################################################
    err_cnt = tester.count_errors()

    if err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    sys.exit(err_cnt)
