#!/usr/bin/env python3

import yaml
import sys
import os
import argparse
from datetime import datetime

parser = argparse.ArgumentParser(description='TS SPECT headers generator')

parser.add_argument("-f", "--file", type=str, default="spect_ops_constants.h",
        help='Destination file name. Default:  "%(default)s"')

parser.add_argument("-c", "--cfg", type=str, default="spect_ops_config.yml",
        help='Configuration input file name. Default:  "%(default)s"')

args = parser.parse_args()

with open(args.cfg, 'r') as f:
    cfg = yaml.safe_load(f)

f = open(args.file, 'w')

file_name = os.path.basename(args.file)

NL = '\n'
H_GUARD = file_name.upper().replace(".", "_")
SPECT_DRAM_OUT_BASE_ADDR_OFFSET = 0x1000

now = datetime.now()
f.write("// Generated on " + now.strftime("%Y-%m-%d %H:%M:%S") + NL )
script_path = os.path.abspath(__file__)
script_name = os.path.basename(script_path)
f.write("// By '" + script_name + "' from 'ts-spect-fw.git'" + NL)
f.write("// Do NOT modify this file, changes will be overwritten by next update" + NL)
f.write(NL)

f.write("#ifndef " + H_GUARD + NL )
f.write("#define " + H_GUARD + NL )

for op in cfg:
    f.write(NL)
    f.write("// " + op["name"] + NL )
    n = op["name"].upper()

    if "id" in op.keys() :
        f.write("#define SPECT_OP_ID_{0} 0x{1:X}".format(n, op["id"]) + NL)

    if "input" in op.keys() and op["input"]:
        for input in op["input"]:
            d = input["name"].upper()
            f.write("#define SPECT_INP_{0}_{1} 0x{2:04X}".format(n, d, input["address"]) + NL)

    if "output" in op.keys() and op["output"]:
        for output in op["output"]:
            d = output["name"].upper()
            a = output["address"] 
            if (a >= SPECT_DRAM_OUT_BASE_ADDR_OFFSET) :
                a = a - SPECT_DRAM_OUT_BASE_ADDR_OFFSET  # TODO: remove offset manipulation after YML fix
            f.write("#define SPECT_OUT_{0}_{1} 0x{2:04X}".format(n, d, a) + NL)

f.write(NL)
f.write("#endif // " + H_GUARD + NL )
f.close()

print(f"File {file_name} successfully written.")
