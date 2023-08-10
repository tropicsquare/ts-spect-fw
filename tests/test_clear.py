#!/usr/bin/env python3
import sys
import os

import test_common as tc

if __name__ == "__main__":

    ops_cfg = tc.get_ops_config()
    test_name = "clear"

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    tc.start(cmd_file)
    ctx = tc.run_op(cmd_file, "clear", 0x0, 0x1, 0, ops_cfg, test_dir, run_name="clear_dummy", main="tests/dummy.s")

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)
    ctx = tc.run_op(cmd_file, "clear", 0x0, 0x1, 0, ops_cfg, test_dir, old_context=ctx)

    data_out = tc.read_output(test_dir, "clear", 0x1000, 128)
    if data_out != 0:
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()
    sys.exit(0)