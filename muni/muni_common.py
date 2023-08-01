import yaml
import binascii
import os
import sys
import numpy as np
import random as rn

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]

sys.path.append(TS_REPO_ROOT)

import tests.test_common as tc

OPS_CONFIG = TS_REPO_ROOT+"/spect_ops_config.yml"

def write_input (cmd_file, cmd_cfg, data_cfg):
    for input in data_cfg["input"]:
        print("Setting input", input["name"])
        addr = tc.find_in_list(input["name"], cmd_cfg["input"])["address"]
        tc.write_string(cmd_file, input["value"], addr)

def set_rng_list (data_cfg, rng_lut) -> list:
    rng_list = [rn.randint(0, 2**256 - 1) for i in range(len(rng_lut))]
    if "rng" in data_cfg.keys():
        for rng in data_cfg["rng"]:
            idx = rng_lut[rng["name"]]
            if rng["value"] is not None:
                print("Forcing rng", rng["name"], "->", hex(rng["value"]))
                rng_list[idx] = rng["value"]
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