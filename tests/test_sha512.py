#!/usr/bin/env python3
import sys
import binascii

import test_common as tc

if __name__ == "__main__":
    ops_cfg = tc.get_ops_config()
    test_name = "sha512"

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    message = "2ef9ff1d7926588de9c68104492034a8a8edab57686d95729de313fc70a8623a86031e5bffd2b8fa2b5daf20a09dae43994d209d24042a34ba17cc6cea8ce40ff13c21fd271db83863eab2d4d9a9b503fe745dcb15da3ef5a607a27f7478bbd18f13b3a29344b73d22e681e9faeb3fedb88c94f7504f8f2ac2f17a09fc33a1f6b83275219d83def87aa1f74537c8819db6759c80fff5b4c42aa09b663c5304d9800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500"
    digest_ref = "a8c8d1c82a66b3eb025a730632201b58395bf3b94146267f618bd8dde204b615c278db94e8da7b88079be199db6b390bca5bef079762e572e2f63f9dc4dbfb16"
    digest_ref_int = int.from_bytes(binascii.unhexlify(digest_ref), 'little')

    m_blocks = []
    for i in range(0, len(message), 256):
        m_blocks.append(message[i:i+256])

    tc.start(cmd_file)
    ctx = tc.run_op(cmd_file, "sha512_init", 0x4, 0x1, 0xabcd, ops_cfg, test_dir)

    for i in range(len(m_blocks)-1):
        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)
        tc.write_string(cmd_file, m_blocks[i], 0x0010)
        ctx = tc.run_op(cmd_file, "sha512_update", 0x4, 0x1, 0xabcd, ops_cfg, test_dir, run_id=i, old_context=ctx)

    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)
    tc.write_string(cmd_file, m_blocks[-1], 0x0010)
    ctx = tc.run_op(cmd_file, "sha512_final", 0x4, 0x1, 0xabcd, ops_cfg, test_dir, old_context=ctx)

    digest = tc.read_output(f"{test_dir}/{test_name}_final_out.hex", 0x1010, 16)

    sys.exit(not(digest == digest_ref_int))
