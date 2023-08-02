import yaml
import binascii
import os
import sys
import yaml
import numpy as np
import random as rn

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]

sys.path.append(TS_REPO_ROOT)

import tests.test_common as tc

OPS_CONFIG = TS_REPO_ROOT+"/spect_ops_config.yml"

def get_cfg(run_name):
    ops_cfg = tc.get_ops_config()
    cmd_cfg = tc.find_in_list(run_name, ops_cfg)
    with open(f"{run_name}_data_cfg.yml", 'r') as data_file:
        data_cfg = yaml.safe_load(data_file)
    return cmd_cfg, data_cfg

def run_init():
    test_dir = os.getcwd() + "/logs"
    print(f"Creating log directory \'{test_dir}\'")
    os.system(f"rm -rf {test_dir}")
    os.system(f"mkdir {test_dir}")
    cmd_file = tc.get_cmd_file(test_dir)
    return test_dir, cmd_file

def get_address(name: str, cmd_cfg, dir):
    offset = tc.find_in_list(name, cmd_cfg[dir])["address"]
    base = tc.find_in_list(name, cmd_cfg[dir])["base"]
    return base + offset

def write_input (cmd_file, cmd_cfg, data_cfg):
    for input in data_cfg["input"]:
        v = input["value"]
        addr = get_address(input["name"], cmd_cfg, "input")
        if type(v) == str:
            print("Setting input", input["name"], v)
            tc.write_string(cmd_file, v, addr)
        elif  type(v) == int:
            print("Setting input", input["name"], hex(v))
            tc.write_int256(cmd_file, v, addr)

def set_rng_list (data_cfg, rng_lut) -> list:
    z = 0
    rng_list = [rn.randint(0, 2**256 - 1) for i in range(4*len(rng_lut))]
    if "rng" in data_cfg.keys():
        for rng in data_cfg["rng"]:
            idx = rng_lut[rng["name"]]["idx"] + z
            if rng["value"] is not None:
                print("Forcing", rng["name"], f"\tindex {idx} ->", hex(rng["value"]))
                rng_list[idx] = rng["value"]
                if rng["value"] == 0 and not rng_lut[rng["name"]]["okzero"]:
                    v = rn.randint(1, 2**256-1)
                    print("Generating alternative mask for", rng["name"], "->", hex(v))
                    z += 1
                    rng_list[idx+1] = v
    return rng_list

def run (cmd_file, test_dir, cmd_cfg, insrc=0x0, outsrc=0x1, data_in_size=0):
    cfg_word = cmd_cfg["id"] + (outsrc << 8) + (insrc << 12) + (data_in_size << 16)
    tc.set_cfg_word(cmd_file, cfg_word)
    tc.run(cmd_file)
    tc.exit(cmd_file)
    cmd_file.close()
    run_name = cmd_cfg["name"]
    run_log = run_name+"_iss.log"
    cmd = "spect_iss"
    cmd += f" --program={TS_REPO_ROOT}/muni/main.s"
    cmd += f" --first-address=0x8000"
    cmd += f" --const-rom={TS_REPO_ROOT}/data/const_rom.hex"
    cmd += f" --grv-hex={test_dir}/rng.hex"
    cmd += f" --data-ram-out={test_dir}/{run_name}_out.hex"
    cmd += f" --shell --cmd-file={test_dir}/iss_cmd > {test_dir}/{run_log}"

    if os.system(cmd):
        print("ISS FAILED")
        sys.exit(2)
