#!/usr/bin/env python3

import yaml
import sys
import os

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]

with open(f"{TS_REPO_ROOT}/spect_ops_config.yml", 'r') as cfg_file:
    cfg = yaml.safe_load(cfg_file)

cfg_file = open(f"{TS_REPO_ROOT}/src/constants/spect_ops_constants.s", 'w')

cfg_file.write(
    "; ==============================================================================\n"
    ";   file    constants/spect_ops_constants.s\n"
    ";   author  tropicsquare s. r. o.\n"
    ";   license TODO\n"
    ";\n"
    ";   generated from spect_ops_config.yml\n"
    "; ==============================================================================\n"
)

for op in cfg:
    cfg_file.write("; " + op["name"] + '\n' )
    cfg_file.write("{} .eq 0x{}\n".format(op["name"]+"_id", format(op["id"], '02X')))
    if "input" in op.keys() and op["input"]:
        for input in op["input"]:
            addr = input["address"]
            if "base" in input.keys() and input["base"]:
                addr += input["base"]
            cfg_file.write("{} .eq 0x{}\n".format(op["name"]+"_input_"+input["name"], format(addr, 'X')))
    if "output" in op.keys() and op["output"]:
        for output in op["output"]:
            addr = output["address"]
            if "base" in output.keys() and output["base"]:
                addr += output["base"]
            cfg_file.write("{} .eq 0x{}\n".format(op["name"]+"_output_"+output["name"], format(addr, 'X')))
    if "context" in op.keys() and op["context"]:
        for context in op["context"]:
            cfg_file.write("{} .eq 0x{}\n".format(op["name"]+"_context_"+context["name"], format(context["address"], 'X')))

cfg_file.close()
