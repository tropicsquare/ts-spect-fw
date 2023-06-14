#!/usr/bin/env python3
import yaml
import sys
import os

import test_common as tc

ops_cfg = tc.get_ops_config()
test_name = "curve25519_rpg"

test_dir = tc.make_test_dir(test_name)
cmd_file = tc.get_cmd_file(test_dir)

tc.start(cmd_file)

ctx = tc.run_op(cmd_file, "curve25519_rpg", ops_cfg, test_dir)

#tc.read_output(test_dir+"/curve25519_rpg_out.hex", 0, 2)
