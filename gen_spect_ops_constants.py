#!/usr/bin/env python3

import yaml
import sys

cfg_name = sys.argv[1]

with open(cfg_name, 'r') as cfg_file:
    cfg = yaml.safe_load(cfg_file)

cfg_file = open("src/spect_ops_constants.s", 'w')

for op in cfg:
    cfg_file.write("; " + op["name"] + '\n' )
    cfg_file.write("{} .eq 0x{}\n".format(op["name"]+"_id", format(op["id"], '02X')))
    if "input" in op.keys() and op["input"]:
        for input in op["input"]:
            cfg_file.write("{} .eq 0x{}\n".format(op["name"]+"_input_"+input["name"], format(input["address"], 'X')))
    if "output" in op.keys() and op["output"]:
        for output in op["output"]:
            cfg_file.write("{} .eq 0x{}\n".format(op["name"]+"_output_"+output["name"], format(output["address"], 'X')))
    if "context" in op.keys() and op["context"]:
        for context in op["context"]:
            cfg_file.write("{} .eq 0x{}\n".format(op["name"]+"_context_"+context["name"], format(context["address"], 'X')))

cfg_file.close()