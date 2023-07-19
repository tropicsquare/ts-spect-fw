#!/usr/bin/env python3
import sys
import binascii

import test_common as tc

if __name__ == "__main__":
    ops_cfg = tc.get_ops_config()
    test_name = "cmd_decode"

    test_dir = tc.make_test_dir(test_name)

    op_list = [ 
        "sha512_init",
        "sha512_update",
        "sha512_final",
        "ecc_key_gen",
        "ecc_key_store",
        "ecc_key_read",
        "ecc_key_erase",
        #"x25519_kpair_gen",
        "x25519_sc_et_eh",
        "x25519_sc_et_sh",
        "x25519_sc_st_eh",
        "eddsa_set_context",
        "eddsa_nonce_init",
        "eddsa_nonce_update",
        "eddsa_nonce_finish",
        "eddsa_R_part",
        "eddsa_e_at_once",
        "eddsa_e_prep",
        "eddsa_e_update",
        "eddsa_e_finish",
        "eddsa_finish",
        "eddsa_verify",
        "ecdsa_sign"
    ]

    for op_name in op_list:
        op = tc.find_in_list(op_name, ops_cfg)
        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)
        tc.run_op(cmd_file, op_name, 0x4, 0x1, 0xabcd, ops_cfg, test_dir)
        id = tc.read_output(f"{test_dir}/{op_name}_out.hex", 0x1120, 1)
        res_word = tc.read_output(f"{test_dir}/{op_name}_out.hex", 0x1100, 1)
        print(op_name, ':', "{}".format(format(res_word, '08X')))
        if not (id == op["id"]):
            tc.print_failed()
            sys.exit(1)
        tc.print_passed()

    sys.exit(0)
