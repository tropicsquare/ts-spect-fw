#!/usr/bin/env python3
import sys
import binascii
import os
import yaml

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]
sys.path.append(TS_REPO_ROOT)

import tests.test_common as tc

rng_lut = {
    "pub_z_rng": 0,
    "s_rng_1": 1,
    "point_gen_rng": 2,
    "s_rng_2" : 3
}

if __name__ == "__main__":
    ops_cfg = tc.get_ops_config()
    test_name = "x25519_dbg"
    run_name = test_name
    cmd_cfg = tc.find_in_list(test_name, ops_cfg)
    tc.print_run_name(run_name)

    test_dir = os.getcwd() + "/logs"
    os.system(f"rm -rf {test_dir}")
    os.system(f"mkdir {test_dir}")
    cmd_file = tc.get_cmd_file(test_dir)

    with open("x25519_dbg_data_cfg.yml", 'r') as data_file:
        data_cfg = yaml.safe_load(data_file)

    tc.start(cmd_file)

    for input in data_cfg["input"]:
        print("Setting input", input["name"])
        addr = tc.find_in_list(input["name"], cmd_cfg["input"])["address"]
        print("Found address", hex(addr))
        tc.write_string(cmd_file, input["value"], addr)

    rng_list = [1 for i in range(len(rng_lut))]

    for rng in data_cfg["rng"]:
        print("Setting rng", rng["name"])
        idx = rng_lut[rng["name"]]
        rng_list[idx] = rng["value"]

    tc.set_rng(test_dir, rng_list)

    ctx = tc.run_op(cmd_file, test_name, 0x0, 0x1, 64, ops_cfg, test_dir, main="muni/main.s")

    res_addr = tc.find_in_list("r", cmd_cfg["output"])["address"]

    res_int = tc.read_output(test_dir, run_name, (0x1 << 12) + res_addr, 8)

    print("Result:", int.to_bytes(res_int, 32, 'little').hex())

    sys.exit(0)
