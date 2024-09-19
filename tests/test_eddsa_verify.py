#!/usr/bin/env python3
import sys
import random as rn

import test_common as tc
import models.ed25519 as ed25519

def __run_test(test_dir:str, run_name:str):

    def __bytes_modify(b: bytes, index: int) -> bytes:
        b = bytearray(b)
        b[index] = ~b[index] & 0xFF
        b = bytes(b)
        return b

    cmd_file = tc.get_cmd_file(test_dir)

    tc.print_run_name(run_name)

    secret = int.to_bytes(rn.randint(0, 2**256-1), 32, 'little')
    msg = int.to_bytes(rn.randint(0, 2**256-1), 32, 'little')
    signature, pub_key = ed25519.sign_standard(secret, msg)

    if run_name.endswith("invalid_r"):
        signature = __bytes_modify(signature, 0)
    elif run_name.endswith("invalid_s"):
        signature = __bytes_modify(signature, -1)
    elif run_name.endswith("invalid_pub_key"):
        pub_key = __bytes_modify(pub_key, -1)
    elif run_name.endswith("invalid_msg"):
        msg = __bytes_modify(msg, -1)

    tc.start(cmd_file)
    tc.write_bytes(cmd_file, signature, 0x0020)
    tc.write_bytes(cmd_file, pub_key, 0x0060)
    tc.write_bytes(cmd_file, msg, 0x0080)
    _ = tc.run_op(
        cmd_file, "eddsa_verify", 0x0, 0x1, 128, ops_cfg, test_dir, run_name=run_name,
        main="src/boot_main.s", tag="Boot2"
    )

    if run_name.endswith("_ok"):
        if tc.read_output(test_dir, run_name, 0x1000, 1) != 0x0B5E55ED:
            tc.print_failed()
            return 1
        elif tc.read_output(test_dir, run_name, 0x1004, 1) != 0xBA11FADE:
            tc.print_failed()
            return 1
        else:
            tc.print_passed()
            return 0
    else:
        if tc.read_output(test_dir, run_name, 0x1000, 1) == 0x0B5E55ED:
            tc.print_failed()
            return 1
        else:
            tc.print_passed()
            return 0

if __name__ == "__main__":

    ops_cfg = tc.get_ops_config()
    test_name = "eddsa_verify"

    test_dir = tc.make_test_dir(test_name)

    ret = 0

    #######################################################################################
    # Valid Signature
    #######################################################################################

    ret |= __run_test(test_dir, f"{test_name}_ok")
    ret |= __run_test(test_dir, f"{test_name}_invalid_r")
    ret |= __run_test(test_dir, f"{test_name}_invalid_s")
    ret |= __run_test(test_dir, f"{test_name}_invalid_pub_key")
    ret |= __run_test(test_dir, f"{test_name}_invalid_msg")

    sys.exit(ret)
