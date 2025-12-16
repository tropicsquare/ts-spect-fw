#!/usr/bin/env python3
import sys
import os
import numpy as np
import random as rn
from binascii import unhexlify

from default_fw import Application

from import_setup import import_setup
import_setup()

from spect_tester.spect_tester import SpectTester
from spect_tester.spect_memory import SpectMem
from spect_tester.spect_context import SpectContext
from spect_tester.spect_config import (
    RAR_STACK_DEPTH,
    SpectOpStatus,
)
from spect_tester.helpers import (
    random_bytes,
)

SHA_CTX_INIT = unhexlify("6a09e667f3bcc908bb67ae8584caa73b3c6ef372fe94f82ba54ff53a5f1d36f1510e527fade682d19b05688c2b3e6c1f1f83d9abfb41bd6b5be0cd19137e2179")

def test_run(tester: SpectTester, run_name: str):

    test_run = tester.create_test_run(run_name)
    test_run.cmd_start()

    test_run.set_op("clear")
    test_run.set_input_source(SpectMem.DataRamIn.src)
    test_run.set_output_source(SpectMem.DataRamOut.src)
    test_run.set_input_size(0)

    input_ctx = SpectContext(
        gpr         = np.array([rn.randint(1, 2**256 - 1) for _ in range(32)]),
        sha         = random_bytes(64),
        tmac        = random_bytes(50),
        rar_stack   = [0]*RAR_STACK_DEPTH,
        rar_pointer = 0,
        flags       = {"Z" : 0, "C" : 0, "E" : 0},
        data_in     = np.array([rn.randint(1, 2**32 - 1) for _ in range(SpectMem.DataRamIn.depth)]),
        data_out    = np.array([rn.randint(1, 2**32 - 1) for _ in range(SpectMem.DataRamOut.depth)])
    )

    input_ctx_file = os.path.join(test_run.run_dir, "input_context")
    input_ctx.dump(input_ctx_file)

    test_run.set_input_context_file(input_ctx_file)

    test_run.run()

    status, data_out_size = test_run.get_res_word()
    test_run.info(f"SPECT Status: 0x{status:02x}")
    test_run.info(f"SPECT OutSize: {data_out_size}")

    if status != SpectOpStatus.RET_OP_SUCCESS.value:
        test_run.error(f"Invalid SPECT Op Status")

    new_ctx = test_run.get_context()

    if any(new_ctx.gpr):
        test_run.error("Data RAM In not cleared!")

    if new_ctx.sha != SHA_CTX_INIT:
        test_run.error("SHA Context not cleared!")

    if any(new_ctx.tmac):
        test_run.error("TMAC Context not cleared!")

    if any(new_ctx.data_in):
        test_run.error("Data RAM In not cleared!")

    if any(new_ctx.data_out):
        test_run.error("Data RAM Out not cleared!")

    emem_out = test_run.read_bytes(SpectMem.EmemOut.base, SpectMem.EmemOut.size)

    if any(emem_out):
        test_run.error("EMEM Out not cleared!")

    test_run.status_summary()

    if test_run.err_cnt == 0:
        SpectTester.print_passed()
    else:
        SpectTester.print_failed()

if __name__ == "__main__":
    test_name = "clear"
    tester = SpectTester(test_name, spect_fw=Application)

    test_run(tester, test_name)

    err_cnt = tester.count_errors()

    sys.exit(err_cnt)
