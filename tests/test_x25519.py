# test vector from https://www.rfc-editor.org/rfc/rfc7748#section-5.2

#!/usr/bin/env python3
import yaml
import sys
import os

import test_common as tc

ops_cfg = tc.get_ops_config()
test_name = "x25519"

test_dir = tc.make_test_dir(test_name)
cmd_file = tc.get_cmd_file(test_dir)

scalar = "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4"
u_coordinate = "e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c"

result = "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552"

tc.start(cmd_file)
tc.write_string(cmd_file, scalar, 0x0020)
tc.write_string(cmd_file, u_coordinate, 0x0040)
ctx = tc.run_op(cmd_file, "x25519", ops_cfg, test_dir)
