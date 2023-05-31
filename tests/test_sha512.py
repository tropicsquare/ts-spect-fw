#!/usr/bin/env python3
import yaml
import sys
import os

import test_common as tc

ops_cfg = tc.get_ops_config()
test_name = "sha512"

cmd_file, test_dir = tc.make_test_dir(test_name)

message = "2ef9ff1d7926588de9c68104492034a8a8edab57686d95729de313fc70a8623a86031e5bffd2b8fa2b5daf20a09dae43994d209d24042a34ba17cc6cea8ce40ff13c21fd271db83863eab2d4d9a9b503fe745dcb15da3ef5a607a27f7478bbd18f13b3a29344b73d22e681e9faeb3fedb88c94f7504f8f2ac2f17a09fc33a1f6b83275219d83def87aa1f74537c8819db6759c80fff5b4c42aa09b663c5304d9800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500"

m_blocks = []
for i in range(0, len(message), 256):
    m_blocks.append(message[i:i+256])

tc.start(cmd_file)
tc.run_op(cmd_file, "sha512_init", ops_cfg)

tc.start(cmd_file)
for block in m_blocks[:-1]:
    tc.write_string(cmd_file, block, 0x0020)
    tc.run_op(cmd_file, "sha512_update", ops_cfg)

tc.start(cmd_file)
tc.write_string(cmd_file, m_blocks[-1], 0x0020)
tc.run_op(cmd_file, "sha512_final", ops_cfg)

tc.exit(cmd_file)

cmd_file.close()

tc.run_test(test_dir)
