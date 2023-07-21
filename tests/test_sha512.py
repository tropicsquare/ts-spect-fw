#!/usr/bin/env python3
import sys
import binascii
import hashlib
import random

import test_common as tc

def sha512(s):
    return hashlib.sha512(s).digest()

if __name__ == "__main__":
    ops_cfg = tc.get_ops_config()
    test_name = "sha512"

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    msg_bitlen = random.randint(2*128, 5*128)*8
    message = int.to_bytes(random.getrandbits(msg_bitlen), msg_bitlen//8, 'big')

    digest_ref = sha512(message)
    digest_ref_int = int.from_bytes(digest_ref, 'little')

    message_padded = message + b'\x80'
    while len(message_padded) % 128 != (128 - 16):
        message_padded += b'\x00'

    message_padded += int.to_bytes(len(message)*8, 16, 'big')

    m_blocks = []
    for i in range(0, len(message_padded), 128):
        m_blocks.append(message_padded[i:i+128])

    tc.print_run_name("sha512_init")
    tc.start(cmd_file)
    ctx = tc.run_op(cmd_file, "sha512_init", 0x0, 0x1, 0, ops_cfg, test_dir)

    for i in range(len(m_blocks)-1):
        tc.print_run_name(f"sha512_update_{i}")
        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)
        tc.write_bytes(cmd_file, m_blocks[i], 0x0010)
        ctx = tc.run_op(cmd_file, "sha512_update", 0x0, 0x1, 128, ops_cfg, test_dir, run_id=i, old_context=ctx)

    tc.print_run_name("sha512_final")
    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)
    tc.write_bytes(cmd_file, m_blocks[-1], 0x0010)
    ctx = tc.run_op(cmd_file, "sha512_final", 0x0, 0x1, 128, ops_cfg, test_dir, old_context=ctx)

    digest = tc.read_output(test_dir, "sha512_final", 0x1010, 16)

    if digest != digest_ref_int:
        tc.print_failed()
        sys.exit(0)

    tc.print_passed()

    sys.exit(0)
