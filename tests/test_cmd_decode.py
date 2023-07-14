#!/usr/bin/env python3
import sys
import binascii

import test_common as tc

if __name__ == "__main__":
    ops_cfg = tc.get_ops_config()
    test_name = "cmd_decode"

    test_dir = tc.make_test_dir(test_name)

    op_list = [ 
        "sha512_init"
        #"sha512_update",
        #"sha512_final",
        #"ecc_key_gen",
        #"ecc_key_store",
        #"ecc_key_read",
        #"ecc_key_erase"
    ]

    for op_name in op_list:
        op = tc.find_in_list(op_name, ops_cfg)
        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)
        tc.run_op(cmd_file, op_name, 0x4, 0x1, 0xabcd, ops_cfg, test_dir)
        id = tc.read_output(f"{test_dir}/{op_name}_out.hex", 0x1000)
        res_word = tc.read_output(f"{test_dir}/{op_name}_out.hex", 0x1100)
        print(op_name, ':', hex(res_word))
        print(id == op["id"])

    sys.exit()
