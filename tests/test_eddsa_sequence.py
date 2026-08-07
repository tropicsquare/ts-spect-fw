#!/usr/bin/env python3
import sys
import os
import random as rn
from enum import Enum

from default_fw import Application

from import_setup import import_setup
import_setup()

from spect_models.EdDSA import EdDSA, KeyPair, Signature
from spect_models.Curves.Ed25519 import Ed25519
from spect_models.Fields.Field255 import Field

from spect_tester.spect_tester import SpectTester, SpectTestRun
from spect_tester.spect_memory import SpectMem
from spect_tester.spect_config import (
    SpectOpStatus,
    L3Result,
    KeyTypes,
    CurveType,
    KeyOrigin,
    EccSlot,
)
from spect_tester.key_memory import KeyMem
from spect_tester.helpers import (
    SlotMetadataErrType,
    random_bytes,
    get_main_defines,
    int2bytes,
    bytes2int,
    get_input_source,
    get_output_source,
    create_metadata,
)

SPECT_FW = Application
defines_set = get_main_defines(SPECT_FW.s_file)

class TestType(Enum):
    OK = 0
    EMPTY_SLOT = 1
    INVALID_CURVE = 2
    INVALID_SLOT_NUMBER = 3

####################################################################################################
####################################################################################################
#   Key Memory Generator
####################################################################################################
####################################################################################################
def create_key_mem(test_type: TestType, Key: KeyPair, slot: int) -> KeyMem:
    keymem = KeyMem()
    if test_type == TestType.EMPTY_SLOT:
        return keymem

    priv_slot = slot<<1
    pub_slot = priv_slot+1

    s2 = rn.randint(1, Ed25519.Q-1)
    s1 = (Key.s - s2) % Ed25519.Q

    prefix_mask = rn.randint(0, 2**256 - 1)
    prefix_masked = Key.prefix ^ prefix_mask

    pub_bytes = Key.PublicBytes(encoding="spect")

    keymem.write(int2bytes(s1),            KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k1'])
    keymem.write(int2bytes(prefix_masked), KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k2'])
    keymem.write(int2bytes(s2),            KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k3'])
    keymem.write(int2bytes(prefix_mask),   KeyTypes.ECC, priv_slot, EccSlot.PRIV_SLOT_LAYOUT['k4'])

    keymem.write(pub_bytes,                KeyTypes.ECC, pub_slot,  EccSlot.PUB_OFFSET)

    if test_type == TestType.INVALID_CURVE:
        curve = CurveType.P256
    else:
        curve = CurveType.ED25519

    if test_type == TestType.INVALID_SLOT_NUMBER:
        slot = slot+1

    pub_metadata, priv_metadata = create_metadata(
        curve            = curve,
        slot             = slot,
        origin           = KeyOrigin.STORE,
        invalid_metadata = SlotMetadataErrType.NO_ERR
    )

    keymem.write(priv_metadata, KeyTypes.ECC, priv_slot, EccSlot.METADATA_OFFSET)
    keymem.write(pub_metadata,  KeyTypes.ECC, pub_slot,  EccSlot.METADATA_OFFSET)

    return keymem

####################################################################################################
####################################################################################################
#   Common Routines
####################################################################################################
####################################################################################################
def __get_and_set_inout_src(test_run: SpectTestRun):
    input_mem = get_input_source(defines_set)
    output_mem = get_output_source(defines_set)

    test_run.set_input_source(input_mem.src)
    test_run.set_output_source(output_mem.src)

    return input_mem, output_mem

def __check_spect_status(test_run: SpectTestRun) -> bool:
    status, data_out_size = test_run.get_res_word()
    test_run.info(f"SPECT Status: 0x{status:02x}")
    test_run.info(f"SPECT OutSize: {data_out_size}")

    if status != SpectOpStatus.RET_OP_SUCCESS:
        test_run.error(
            f"Invalid SPECT Op Status\n"+
            f"\tExpected {SpectOpStatus.RET_OP_SUCCESS:02x}\n"+
            f"\tObserved {status:02x}"
        )
        return False

    return True

####################################################################################################
####################################################################################################
#   EdDSA Sign - Atomic Calls
####################################################################################################
####################################################################################################
def eddsa_set_context(test_run: SpectTestRun, slot: int, scn: bytes, sch: bytes) -> bool:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_set_context")

    test_run.write_bytes(SpectMem.DataRamIn.base+0xA0, sch)
    test_run.write_bytes(SpectMem.DataRamIn.base+0xC0, scn)

    input_mem, _ = __get_and_set_inout_src(test_run)

    l3_input_word = (slot<<8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    test_run.set_input_size(4)

    test_run.run()

    return __check_spect_status(test_run)

def eddsa_nonce_init(test_run: SpectTestRun) -> bool:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_nonce_init")

    _, _ = __get_and_set_inout_src(test_run)

    test_run.set_input_size(0)

    test_run.run()

    return __check_spect_status(test_run)

def eddsa_nonce_update(test_run: SpectTestRun, block: bytes) -> bool:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_nonce_update")

    input_mem, _ = __get_and_set_inout_src(test_run)

    test_run.write_bytes(input_mem.base, block)
    test_run.set_input_size(len(block))

    test_run.run()

    return __check_spect_status(test_run)

def eddsa_nonce_finish(test_run: SpectTestRun, block: bytes) -> bool:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_nonce_finish")

    input_mem, _ = __get_and_set_inout_src(test_run)

    test_run.write_bytes(input_mem.base, block)
    test_run.set_input_size(len(block))

    test_run.run()

    return __check_spect_status(test_run)

def eddsa_r_part(test_run: SpectTestRun) -> bool:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_R_part")

    _, _ = __get_and_set_inout_src(test_run)

    test_run.set_input_size(0)

    test_run.run()

    return __check_spect_status(test_run)

def eddsa_e_at_once(test_run: SpectTestRun, block: bytes) -> bool:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_e_at_once")

    input_mem, _ = __get_and_set_inout_src(test_run)

    test_run.write_bytes(input_mem.base, block)
    test_run.set_input_size(len(block))

    test_run.run()

    return __check_spect_status(test_run)

def eddsa_e_prep(test_run: SpectTestRun, block: bytes) -> bool:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_e_prep")

    input_mem, _ = __get_and_set_inout_src(test_run)

    test_run.write_bytes(input_mem.base, block)
    test_run.set_input_size(len(block))

    test_run.run()

    return __check_spect_status(test_run)

def eddsa_e_update(test_run: SpectTestRun, block: bytes) -> bool:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_e_update")

    input_mem, _ = __get_and_set_inout_src(test_run)

    test_run.write_bytes(input_mem.base, block)
    test_run.set_input_size(len(block))

    test_run.run()

    return __check_spect_status(test_run)

def eddsa_e_finish(test_run: SpectTestRun, block: bytes) -> bool:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_e_finish")

    input_mem, _ = __get_and_set_inout_src(test_run)

    test_run.write_bytes(input_mem.base, block)
    test_run.set_input_size(len(block))

    test_run.run()

    return __check_spect_status(test_run)

def eddsa_finish(test_run: SpectTestRun) -> bytes:
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_finish")

    _, output_mem = __get_and_set_inout_src(test_run)

    test_run.set_input_size(0)

    test_run.run()

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

    if data_out_size != 80:
        test_run.error("Invalid output size")

    signature = test_run.read_bytes(output_mem.base+0x10, 64)

    return signature

####################################################################################################
####################################################################################################
#   EdDSA Sign - Sequence
####################################################################################################
####################################################################################################
def eddsa_sign(
    tester: SpectTester,
    init_keymem_file: str,
    message: bytes,
    scn: bytes,
    sch: bytes,
    slot: int
):

    def __pass_test_run_context(tester: SpectTester, prev_name: str, new_name: str) -> SpectTestRun:
        new_run = tester.create_test_run(new_name)

        new_run.set_input_context_file(tester.get_test_run(prev_name).context_file)
        new_run.set_input_keymem_file(tester.get_test_run(prev_name).keymem_file)

        return new_run

    ################################################################################################
    #   Set Context
    ################################################################################################
    curr_run_name = "set_context"
    tester.create_test_run(curr_run_name)
    curr_run = tester.get_test_run(curr_run_name)

    curr_run.set_input_keymem_file(init_keymem_file)

    tester.info(f"Running {curr_run_name}")

    if not eddsa_set_context(curr_run, slot, scn, sch):
        return None

    prev_run_name = curr_run_name
    ################################################################################################
    #   Compute Nonce
    ################################################################################################
    # Init
    curr_run_name = "nonce_init"
    curr_run = __pass_test_run_context(tester, prev_run_name, curr_run_name)

    tester.info(f"Running {curr_run_name}")

    if not eddsa_nonce_init(curr_run):
        return None

    prev_run_name = curr_run_name

    # Update
    updates_cnt = len(message) // 144

    # If the message size is a multiple of 144 bytes, flip a coin if last
    # block will be processed by 'update' or 'finish' command
    if (len(message) % 144 == 0) and (rn.randint(0,1) == 1):
        updates_cnt -= 1

    for i in range(0, updates_cnt):
        curr_run_name = f"nonce_update_{i}"
        curr_run = __pass_test_run_context(tester, prev_run_name, curr_run_name)

        block = message[(i*144) : (i*144)+144]
        tester.info(f"Running {curr_run_name}, block size: {len(block)}")

        if not eddsa_nonce_update(curr_run, block):
            return None

        prev_run_name = curr_run_name

    # Finish
    curr_run_name = f"nonce_finish"
    curr_run = __pass_test_run_context(tester, prev_run_name, curr_run_name)

    last_block = message[updates_cnt*144:]
    tester.info(f"Running {curr_run_name}, block size: {len(last_block)}")

    if not eddsa_nonce_finish(curr_run, last_block):
        return None

    prev_run_name = curr_run_name
    ################################################################################################
    #   Compute R Part
    ################################################################################################
    curr_run_name = f"r_part"
    curr_run = __pass_test_run_context(tester, prev_run_name, curr_run_name)

    tester.info(f"Running {curr_run_name}")

    if not eddsa_r_part(curr_run):
        return None

    prev_run_name = curr_run_name
    ################################################################################################
    #   Compute E
    ################################################################################################
    if len(message) < 64:
        # E At Once
        curr_run_name = f"e_at_once"
        curr_run = __pass_test_run_context(tester, prev_run_name, curr_run_name)

        tester.info(f"Running {curr_run_name}, block size: {len(message)}")

        if not eddsa_e_at_once(curr_run, message):
            return None

        prev_run_name = curr_run_name
    else:
        # E Prepare
        curr_run_name = f"e_prepare"
        curr_run = __pass_test_run_context(tester, prev_run_name, curr_run_name)

        block = message[:64]
        tester.info(f"Running {curr_run_name}, block size: {len(block)}")

        if not eddsa_e_prep(curr_run, block):
            return None

        prev_run_name = curr_run_name

        # E Update
        message_tmp = message[64:]
        updates_cnt = len(message_tmp) // 128

        # If the rest of message size is a multiple of 128 bytes, flip a coin if last
        # block will be processed by 'update' or 'finish' command
        if (len(message_tmp) % 128 == 0) and (rn.randint(0,1) == 1):
            updates_cnt -= 1

        for i in range(0, updates_cnt):
            curr_run_name = f"e_update_{i}"
            curr_run = __pass_test_run_context(tester, prev_run_name, curr_run_name)

            block = message_tmp[(i*128) : (i*128)+128]
            tester.info(f"Running {curr_run_name}, block size: {len(block)}")

            if not eddsa_e_update(curr_run, block):
                return None

            prev_run_name = curr_run_name

        # E Finish
        curr_run_name = f"e_finish"
        curr_run = __pass_test_run_context(tester, prev_run_name, curr_run_name)

        last_block = message_tmp[updates_cnt*128:]
        tester.info(f"Running {curr_run_name}, block size: {len(last_block)}")

        if not eddsa_e_finish(curr_run, last_block):
            return None

        prev_run_name = curr_run_name

    ################################################################################################
    #   Finish
    ################################################################################################
    curr_run_name = f"finish"
    curr_run = __pass_test_run_context(tester, prev_run_name, curr_run_name)

    tester.info(f"Running {curr_run_name}")

    signature = eddsa_finish(curr_run)

    return signature

####################################################################################################
####################################################################################################
#   Tests
####################################################################################################
####################################################################################################
def test_ok(msg_len: int):
    test_name = f"eddsa_sign_ok_{msg_len}"
    tester = SpectTester(test_name, spect_fw=Application)
    init_keymem_file = os.path.join(tester.test_dir, "init_keymem")

    ################################################################################################
    #   Generate Test Vector
    ################################################################################################
    slot = rn.randint(0,31)

    k = random_bytes(32)
    Key = EdDSA.KeyGen(k)

    create_key_mem(TestType.OK, Key, slot).dump(init_keymem_file)

    message = random_bytes(msg_len)
    sch = random_bytes(32)
    scn = random_bytes(4)

    tester.info(
        "Test Vector:\n"+
        f"    slot:     {slot}\n"+
        f"    k:        {k.hex()}\n"+
        f"    msg:      {message.hex()}\n"+
        f"    msg len:  {msg_len}\n"+
        f"    sch:      {sch}\n"+
        f"    scn:      {scn}\n"
    )

    signature_ref = EdDSA.Sign(message, Key, sch, scn).to_bytes()
    tester.info(f"Signature ref: {signature_ref.hex()}")

    ################################################################################################
    #   Run and Check
    ################################################################################################
    signature = eddsa_sign(
        tester,
        init_keymem_file    = init_keymem_file,
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
    #   END Test
    ################################################################################################
    err_cnt = tester.count_errors()

    if err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    return err_cnt

def test_err(test_type: TestType):
    test_name = f"eddsa_sign_err_{test_type.name.lower()}"
    tester = SpectTester(test_name, spect_fw=Application)
    init_keymem_file = os.path.join(tester.test_dir, "init_keymem")

    ################################################################################################
    #   Generate Test Vector
    ################################################################################################
    slot = rn.randint(0,31)

    k = random_bytes(32)
    Key = EdDSA.KeyGen(k)

    create_key_mem(test_type, Key, slot).dump(init_keymem_file)

    sch = random_bytes(32)
    scn = random_bytes(4)

    ################################################################################################
    #   Run Test
    ################################################################################################
    test_run = tester.create_test_run(f"eddsa_{test_type.name.lower()}")
    test_run.cmd_start()
    test_run.set_rng()
    test_run.set_op("eddsa_set_context")

    test_run.set_input_keymem_file(init_keymem_file)

    test_run.write_bytes(SpectMem.DataRamIn.base+0xA0, sch)
    test_run.write_bytes(SpectMem.DataRamIn.base+0xC0, scn)

    input_mem, output_mem = __get_and_set_inout_src(test_run)

    l3_input_word = (slot<<8) + test_run.op_dict.get('id', 0xFF)
    test_run.write_word(input_mem.base, l3_input_word)

    test_run.set_input_size(4)

    test_run.run()

    status, data_out_size = test_run.get_res_word()
    test_run.info(f"SPECT Status: 0x{status:02x}")
    test_run.info(f"SPECT OutSize: {data_out_size}")

    if test_type == TestType.EMPTY_SLOT:
        expected_status = SpectOpStatus.RET_KEY_ERR
    elif test_type == TestType.INVALID_CURVE:
        expected_status = SpectOpStatus.RET_CURVE_TYPE_ERR
    elif test_type == TestType.INVALID_SLOT_NUMBER:
        expected_status = SpectOpStatus.RET_SLOT_METADATA_ERR
    else:
        expected_status = None
        test_run.critical("Invalid test type for error run!")

    if status != expected_status:
        test_run.error(
            f"Invalid SPECT Op Status\n"+
            f"\tExpected {expected_status:02x}\n"+
            f"\tObserved {status:02x}"
        )

    l3_result_word = test_run.read_word(output_mem.base)
    assert l3_result_word is not None

    l3_result = l3_result_word & 0xFF
    if l3_result != L3Result.L3_RESULT_INVALID_KEY:
        test_run.error(
            f"Invalid L3 Result\n"+
            f"\tExpected {L3Result.L3_RESULT_INVALID_KEY:02x}\n"+
            f"\tObserved {l3_result:02x}"
        )

    if data_out_size != 1:
        test_run.error("Invalid output size")

    ################################################################################################
    #   END Test
    ################################################################################################
    err_cnt = tester.count_errors()

    if err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    return err_cnt

####################################################################################################
####################################################################################################
#   Main
####################################################################################################
####################################################################################################
if __name__ == "__main__":
    ret = 0

    # Randomized message size
    ret += test_ok(msg_len=rn.randint(1, 63))
    ret += test_ok(msg_len=rn.randint(65, 127))
    ret += test_ok(msg_len=rn.randint(128, 142))
    ret += test_ok(msg_len=rn.randint(145, 600))

    # Edge case message size
    ret += test_ok(msg_len=0)
    ret += test_ok(msg_len=64)
    ret += test_ok(msg_len=143)
    ret += test_ok(msg_len=144)
    ret += test_ok(msg_len=320)

    # Error
    ret += test_err(TestType.EMPTY_SLOT)
    ret += test_err(TestType.INVALID_CURVE)
    ret += test_err(TestType.INVALID_SLOT_NUMBER)

    sys.exit(ret)
