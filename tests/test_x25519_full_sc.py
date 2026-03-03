#!/usr/bin/env python3
import sys
import os
import random as rn
from enum import Enum

from default_fw import Application

from import_setup import import_setup
import_setup()

from spect_tester.spect_tester import SpectTester
from spect_tester.spect_memory import SpectMem
from spect_tester.spect_config import (
    SpectOpStatus,
    KeyTypes,
)
from spect_tester.key_memory import KeyMem
from spect_tester.helpers import (
    get_main_defines,
    int2bytes,
    bytes2int,
)

import models.x25519 as x25519

class TestType(Enum):
    OK = 0
    EMPTY_SLOT = 1
    INVALID_PUB_FIELD = 2
    INVALID_PUB_SQRR = 3
    # Not Implemented in FW
    #INVALID_PUB_INF = 4

OP_KPAIR_GEN = "x25519_kpair_gen"
OP_ET_EH = "x25519_sc_et_eh"
OP_ET_SH = "x25519_sc_et_sh"
OP_ST_EH = "x25519_sc_st_eh"

EXPECTED_STATUS = {
    TestType.OK : {
        OP_KPAIR_GEN: SpectOpStatus.RET_OP_SUCCESS,
        OP_ET_EH: SpectOpStatus.RET_OP_SUCCESS,
        OP_ET_SH: SpectOpStatus.RET_OP_SUCCESS,
        OP_ST_EH: SpectOpStatus.RET_OP_SUCCESS,
    },
    TestType.EMPTY_SLOT : {
        OP_KPAIR_GEN: SpectOpStatus.RET_OP_SUCCESS,
        OP_ET_EH: SpectOpStatus.RET_OP_SUCCESS,
        OP_ET_SH: SpectOpStatus.RET_KEY_ERR,
        OP_ST_EH: SpectOpStatus.RET_CTX_ERR,
    },
    TestType.INVALID_PUB_FIELD : {
        OP_KPAIR_GEN: SpectOpStatus.RET_OP_SUCCESS,
        OP_ET_EH: SpectOpStatus.RET_X25519_ERR_INV_PUB_KEY,
        OP_ET_SH: SpectOpStatus.RET_CTX_ERR,
        OP_ST_EH: SpectOpStatus.RET_CTX_ERR,
    },
    TestType.INVALID_PUB_SQRR : {
        OP_KPAIR_GEN: SpectOpStatus.RET_OP_SUCCESS,
        OP_ET_EH: SpectOpStatus.RET_X25519_ERR_INV_PUB_KEY,
        OP_ET_SH: SpectOpStatus.RET_CTX_ERR,
        OP_ST_EH: SpectOpStatus.RET_CTX_ERR,
    },
    #TestType.INVALID_PUB_INF : {
    #    OP_KPAIR_GEN: SpectOpStatus.RET_OP_SUCCESS,
    #    OP_ET_EH: SpectOpStatus.RET_X25519_ERR_INV_PUB_KEY,
    #    OP_ET_SH: SpectOpStatus.RET_CTX_ERR,
    #    OP_ST_EH: SpectOpStatus.RET_CTX_ERR,
    #}
}

EXPECTED_DATA_SIZE = {
    TestType.OK : {
        OP_KPAIR_GEN: 32,
        OP_ET_EH: 32,
        OP_ET_SH: 32,
        OP_ST_EH: 32,
    },
    TestType.EMPTY_SLOT : {
        OP_KPAIR_GEN: 32,
        OP_ET_EH: 32,
        OP_ET_SH: 0,
        OP_ST_EH: 0,
    },
    TestType.INVALID_PUB_FIELD : {
        OP_KPAIR_GEN: 32,
        OP_ET_EH: 0,
        OP_ET_SH: 0,
        OP_ST_EH: 0,
    },
    TestType.INVALID_PUB_SQRR : {
        OP_KPAIR_GEN: 32,
        OP_ET_EH: 0,
        OP_ET_SH: 0,
        OP_ST_EH: 0,
    },
    #TestType.INVALID_PUB_INF : {
    #    OP_KPAIR_GEN: 32,
    #    OP_ET_EH: 32,
    #    OP_ET_SH: 32,
    #    OP_ST_EH: 32,
    #}
}

SPECT_FW = Application
defines_set = get_main_defines(SPECT_FW.s_file)

def gen_invalid_pub() -> int:
    is_square = True
    x = 0
    while(is_square != False):
        x = rn.randint(1, x25519.p -1)
        y2 = (x*x*x + x*x*x25519.A + x) % x25519.p

        is_square = (pow(y2, (x25519.p-1)//2, x25519.p)) in [0,1]

    return x

def test_run(tester: SpectTester, test_type: TestType):
    ################################################################################################
    #   Generate Test Vector
    ################################################################################################
    # calculate etpub and etpriv
    etpriv_1 = rn.randint(0, 2**256-1)
    etpriv_2 = rn.randint(0, 2**256-1)
    etpriv = ((etpriv_2 << 256) | etpriv_1) % (2**256-1)
    etpriv_scalar = x25519.int2scalar(etpriv)
    etpub = x25519.x25519(etpriv_scalar, 9)

    tester.info(
        f"Ephemeral Tropic:\n"+
        f"\tPriv: 0x{etpriv_scalar:064x}\n"+
        f"\tPub:  0x{etpub:064x}\n"
    )

    # calculate stpub a stpriv
    stpriv = rn.randint(0, 2**256-1)
    stpriv_scalar = x25519.int2scalar(stpriv)
    stpub = x25519.x25519(stpriv_scalar, 9)

    tester.info(
        f"Static Tropic:\n"+
        f"\tPriv: 0x{stpriv_scalar:064x}\n"+
        f"\tPub:  0x{stpub:064x}\n"
    )

    # calculate ehpub and ehpriv
    ehpriv = rn.randint(0, 2**256-1)
    ehpriv_scalar = x25519.int2scalar(ehpriv)
    ehpub = x25519.x25519(ehpriv_scalar, 9)

    if test_type == TestType.INVALID_PUB_FIELD:
        ehpub = rn.randint(x25519.p, 2**256-1)
    elif test_type == TestType.INVALID_PUB_SQRR:
        ehpub = gen_invalid_pub()
    #elif test_type == TestType.INVALID_PUB_INF:
    #    ehpub = 0

    tester.info(
        f"Ephemeral Host:\n"+
        f"\tPriv: 0x{ehpriv_scalar:064x}\n"+
        f"\tPub:  0x{ehpub:064x}\n"
    )

    # calculate shpub and shpriv
    shpriv = rn.randint(0, 2**256-1)
    shpriv_scalar = x25519.int2scalar(ehpriv)
    shpub = x25519.x25519(shpriv_scalar, 9)

    tester.info(
        f"Static Host:\n"+
        f"\tPriv: 0x{shpriv_scalar:064x}\n"+
        f"\tPub:  0x{shpub:064x}\n"
    )

    X1_int = x25519.x25519(etpriv_scalar, ehpub)
    R2_int = x25519.x25519(etpriv_scalar, shpub)
    R3_int = x25519.x25519(stpriv_scalar, ehpub)

    tester.info(f"X1: 0x{X1_int:064x}")
    tester.info(f"R2: 0x{R2_int:064x}")
    tester.info(f"R3: 0x{R3_int:064x}")

    slot = rn.randint(0,3)
    tester.info(f"Slot: {slot}")

    init_keymem_file = os.path.join(tester.test_dir, "init_keymem")
    keymem = KeyMem()
    if test_type != TestType.EMPTY_SLOT:
        keymem.write(int2bytes(shpub), KeyTypes.SHPUB, slot, offset=0)

    keymem.write(int2bytes(stpriv), KeyTypes.STPRIV, slot=0, offset=0)
    keymem.dump(init_keymem_file)

    ################################################################################################
    #   X25519 Key Pair Gen
    ################################################################################################
    run_name = OP_KPAIR_GEN
    test_run_kpg = tester.create_test_run(run_name)
    test_run_kpg.set_input_keymem_file(init_keymem_file)
    test_run_kpg.cmd_start()
    test_run_kpg.set_op(run_name)

    rng = [etpriv_1] + [etpriv_2] + [rn.randint(0, 2**256-1) for _ in range(8)]
    test_run_kpg.set_rng(rng)

    test_run_kpg.run()

    status, data_out_size = test_run_kpg.get_res_word()
    test_run_kpg.info(f"SPECT Status: 0x{status:02x}")
    test_run_kpg.info(f"SPECT OutSize: {data_out_size}")

    expected_status = EXPECTED_STATUS[test_type][run_name]
    expected_data_out_size = EXPECTED_DATA_SIZE[test_type][run_name]

    if status != expected_status:
        test_run_kpg.error(
            f"Invalid SPECT Op Status\n"+
            f"\tExpected {expected_status:02x}\n"+
            f"\tObserved {status:02x}"
        )

    if data_out_size != expected_data_out_size:
        test_run_kpg.error("Invalid output size")

    if expected_status == SpectOpStatus.RET_OP_SUCCESS:
        r_etpub = test_run_kpg.read_bytes(SpectMem.DataRamOut.base + 0x20, data_out_size)
        r_etpub_int = bytes2int(r_etpub)
        test_run_kpg.info(f"ETPUB result: 0x{r_etpub_int:064x}")

        if r_etpub_int != etpub:
            test_run_kpg.error("ETPUB Mismatch")

    test_run_kpg.status_summary()

    ################################################################################################
    #   X25519 ET EH
    ################################################################################################
    run_name = OP_ET_EH
    test_run_et_eh = tester.create_test_run(run_name)
    test_run_et_eh.set_input_keymem_file(test_run_kpg.keymem_file)
    test_run_et_eh.set_input_context_file(test_run_kpg.context_file)
    test_run_et_eh.cmd_start()
    test_run_et_eh.set_op(run_name)

    test_run_et_eh.set_rng()

    test_run_et_eh.write_bytes(SpectMem.DataRamIn.base+0x20, int2bytes(ehpub))
    test_run_et_eh.set_input_size(32)

    test_run_et_eh.run()

    status, data_out_size = test_run_et_eh.get_res_word()
    test_run_et_eh.info(f"SPECT Status: 0x{status:02x}")
    test_run_et_eh.info(f"SPECT OutSize: {data_out_size}")

    expected_status = EXPECTED_STATUS[test_type][run_name]
    expected_data_out_size = EXPECTED_DATA_SIZE[test_type][run_name]

    if status != expected_status:
        test_run_et_eh.error(
            f"Invalid SPECT Op Status\n"+
            f"\tExpected {expected_status:02x}\n"+
            f"\tObserved {status:02x}"
        )

    if data_out_size != expected_data_out_size:
        test_run_et_eh.error("Invalid output size")

    if expected_status == SpectOpStatus.RET_OP_SUCCESS:
        r_X1 = test_run_et_eh.read_bytes(SpectMem.DataRamOut.base + 0x20, data_out_size)
        r_X1_int = bytes2int(r_X1)
        test_run_et_eh.info(f"X1 result: 0x{r_X1_int:064x}")

        if r_X1_int != X1_int:
            test_run_et_eh.error("X1 Mismatch")

    test_run_et_eh.status_summary()

    ################################################################################################
    #   X25519 ET SH
    ################################################################################################
    run_name = OP_ET_SH
    test_run_et_sh = tester.create_test_run(run_name)
    test_run_et_sh.set_input_keymem_file(test_run_et_eh.keymem_file)
    test_run_et_sh.set_input_context_file(test_run_et_eh.context_file)
    test_run_et_sh.cmd_start()
    test_run_et_sh.set_op(run_name)

    test_run_et_sh.set_rng()

    test_run_et_sh.write_word(SpectMem.DataRamIn.base+0x20, slot)
    test_run_et_sh.set_input_size(1)

    test_run_et_sh.run()

    status, data_out_size = test_run_et_sh.get_res_word()
    test_run_et_sh.info(f"SPECT Status: 0x{status:02x}")
    test_run_et_sh.info(f"SPECT OutSize: {data_out_size}")

    expected_status = EXPECTED_STATUS[test_type][run_name]
    expected_data_out_size = EXPECTED_DATA_SIZE[test_type][run_name]

    if status != expected_status:
        test_run_et_sh.error(
            f"Invalid SPECT Op Status\n"+
            f"\tExpected {expected_status:02x}\n"+
            f"\tObserved {status:02x}"
        )

    if data_out_size != expected_data_out_size:
        test_run_et_sh.error("Invalid output size")

    if expected_status == SpectOpStatus.RET_OP_SUCCESS:
        r_R2 = test_run_et_sh.read_bytes(SpectMem.DataRamOut.base + 0x20, data_out_size)
        r_R2_int = bytes2int(r_R2)
        test_run_et_sh.info(f"R2 result: 0x{r_R2_int:064x}")

        if r_R2_int != R2_int:
            test_run_et_sh.error("R2 Mismatch")

    test_run_et_sh.status_summary()

    ################################################################################################
    #   X25519 ST EH
    ################################################################################################
    run_name = OP_ST_EH
    test_run_st_eh = tester.create_test_run(run_name)
    test_run_st_eh.set_input_keymem_file(test_run_et_sh.keymem_file)
    test_run_st_eh.set_input_context_file(test_run_et_sh.context_file)
    test_run_st_eh.cmd_start()
    test_run_st_eh.set_op(run_name)

    test_run_st_eh.set_rng()

    test_run_st_eh.write_bytes(SpectMem.DataRamIn.base+0x20, int2bytes(ehpub))
    test_run_st_eh.set_input_size(1)

    test_run_st_eh.run()

    status, data_out_size = test_run_st_eh.get_res_word()
    test_run_st_eh.info(f"SPECT Status: 0x{status:02x}")
    test_run_st_eh.info(f"SPECT OutSize: {data_out_size}")

    expected_status = EXPECTED_STATUS[test_type][run_name]
    expected_data_out_size = EXPECTED_DATA_SIZE[test_type][run_name]

    if status != expected_status:
        test_run_st_eh.error(
            f"Invalid SPECT Op Status\n"+
            f"\tExpected {expected_status:02x}\n"+
            f"\tObserved {status:02x}"
        )

    if data_out_size != expected_data_out_size:
        test_run_st_eh.error("Invalid output size")

    if expected_status == SpectOpStatus.RET_OP_SUCCESS:
        r_R3 = test_run_st_eh.read_bytes(SpectMem.DataRamOut.base + 0x20, data_out_size)
        r_R3_int = bytes2int(r_R3)
        test_run_st_eh.info(f"R3 result: 0x{r_R3_int:064x}")

        if r_R3_int != R3_int:
            test_run_st_eh.error("R3 Mismatch")

    test_run_st_eh.status_summary()

    ################################################################################################
    #   END
    ################################################################################################
    err_cnt = tester.count_errors()

    if err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    return err_cnt

if __name__ == "__main__":
    ret = 0

    for test_type in TestType:
        test_name = f"x25519_sc_{test_type.name.lower()}"
        ret += test_run(SpectTester(test_name, spect_fw=Application), test_type)

    sys.exit(ret)
