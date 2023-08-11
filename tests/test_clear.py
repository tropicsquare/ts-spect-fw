#!/usr/bin/env python3
import sys
import os

import test_common as tc

if __name__ == "__main__":

    ops_cfg = tc.get_ops_config()
    test_name = "clear"

    tc.print_run_name("clear")

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    tc.start(cmd_file)
    ctx = tc.run_op(cmd_file, "clear", 0x0, 0x1, 0, ops_cfg, test_dir, run_name="clear_dummy", main="tests/dummy.s")

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)
    ctx = tc.run_op(cmd_file, "clear", 0x0, 0x1, 0, ops_cfg, test_dir, old_context=ctx)

    ctx_dict = tc.parse_context(test_dir, "clear")

    ret = 0

    for i in range(32):
        if ctx_dict["GPR"][i] != 0:
            print(f"r{i} != 0")
            ret = 1
    
    if ctx_dict["SHA"] != tc.SHA_CTX_INIT:
        print("SHA ctx != Init ctx")
        ret = 1
    
    if int.from_bytes(ctx_dict["TMAC"], 'big') != 0:
        print("TMAC ctx not cleared")
        ret = 1

    for i in range(tc.DATA_RAM_IN_DEPTH):
        if ctx_dict["DATA RAM IN"][i] != 0:
            print(f"Data RAM In {hex(i)} is not cleared")
            ret = 1
    
    for i in range(tc.DATA_RAM_OUT_DEPTH):
        if ctx_dict["DATA RAM OUT"][i] != 0:
            print(f"Data RAM Out {hex(i)} is not cleared")
            ret = 1

    if ret:
        tc.print_failed()
    else:
        tc.print_passed()

    sys.exit(ret)
