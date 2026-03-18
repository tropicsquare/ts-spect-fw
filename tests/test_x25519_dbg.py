#!/usr/bin/env python3
import sys
import random as rn

from default_fw import Application

from import_setup import import_setup
import_setup()

from spect_models.Curves.Curve25519 import Curve25519, CURVE25519_BASE, int2scalar
from spect_models.Fields.Field255 import Field

from spect_tester.spect_tester import SpectTester
from spect_tester.spect_memory import SpectMem
from spect_tester.spect_config import (
    SpectOpStatus,
)
from spect_tester.helpers import (
    get_main_defines,
    int2bytes,
)

SPECT_FW = Application
defines_set = get_main_defines(SPECT_FW.s_file)

def test_run(tester: SpectTester):

    priv = rn.randint(0, 2**256-1)
    priv_scalar = int2scalar(priv)
    pub = CURVE25519_BASE.spm(priv_scalar)

    R_ref = pub.spm(priv_scalar)

    run_name = "x25519_dbg"
    test_run = tester.create_test_run(run_name)

    test_run.cmd_start()
    test_run.set_op("x25519_dbg")
    test_run.set_rng()

    test_run.write_bytes(SpectMem.DataRamIn.base+0x20, int2bytes(priv_scalar))
    test_run.write_bytes(SpectMem.DataRamIn.base+0x40, pub.to_bytes())

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

    if data_out_size != 32:
        test_run.error("Invalid output size")

    R = test_run.read_bytes(SpectMem.DataRamOut.base+0x20, data_out_size)

    if R != R_ref.to_bytes():
        test_run.error("Result mismatch")

if __name__ == "__main__":
    tester = SpectTester("x25519_dbg", spect_fw=Application)

    if "DEBUG_OPS" not in defines_set:
        SpectTester.print_test_skipped("Debug ops are disabled")
        sys.exit(0)

    test_run(tester)

    err_cnt = tester.count_errors()

    if err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

    sys.exit(err_cnt)
