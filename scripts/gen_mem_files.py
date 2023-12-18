#!/usr/bin/env python3

import yaml
import sys
import os
import numpy as np
import random as rn
import binascii

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]

def addr_sort(it):
    return it["address"]

config_name = sys.argv[1]

with open(config_name, 'r') as mem_file:
    mem = yaml.safe_load(mem_file)

mem_size = int((mem["end_addr"] - mem["start_addr"] + 1) / 32)

data = np.empty(mem_size)


if len(mem["data"]) > mem_size:
    print("Memory size error")

mem_hex_name = os.path.join(os.path.dirname(sys.argv[1]), mem["name"] + ".hex")
mem_layout_name = os.path.join(os.path.dirname(sys.argv[1]), mem["name"] + "_layout.s")
print("hexfile -> ", mem_hex_name)
print("layout -> ", mem_layout_name)
mem_hex = open(mem_hex_name, "w")
mem_layout = open(mem_layout_name, "w")

mem_layout.write(
    "; ==============================================================================\n"
    f";   file    mem_layouts/{mem_layout_name.split('/')[-1]}\n"
    ";   author  tropicsquare s. r. o.\n"
    "; \n"
    ";  Copyright © 2023 Tropic Square s.r.o. (https://tropicsquare.com/)            \n"
    ";  This work is subject to the license terms of the LICENSE.txt file in the root\n"
    ";  directory of this source tree.                                               \n" 
    ";  If a copy of the LICENSE file was not distributed with this work, you can    \n" 
    ";  obtain one at (https://tropicsquare.com/license).                            \n"
    ";\n"
    f";   generated from {config_name.split('/')[-1]}\n"
    "; ==============================================================================\n"
)

data = np.empty(mem_size, dtype=dict)

for d in mem["data"]:
    if "value" not in d.keys():
        d["value"] = 0
    if "is_string" in d.keys() and d["is_string"]:
        d["value"] = int.from_bytes(binascii.unhexlify(d["value"]), 'little')

for d in mem["data"]:
    if "address" in d.keys():
        if d["address"] % 32 != 0:
            print(d["name"], "address error.")
        data[int(d["address"]/32)] = {
            "name" : d["name"],
            "address" : d["address"],
            "value" : d["value"]
        }

for d in mem["data"]:
    if "address" not in d.keys():
        for i in range(len(mem["data"])):
            if data[i] == None:
                data[i] = {
                    "name" : d["name"],
                    "address" : mem["start_addr"] + i*32,
                    "value" : d["value"]
                }
                break

for d in data:
    if d == None:
        for i in range(8):
            mem_hex.write("00000000\n")
    else:
        for i in range(8):
            mem_hex.write(format((d["value"] >> i*32) & 0xffffffff, '08X') + "\n")

        mem_layout.write("{} .eq 0x{}\n".format(d["name"], format(d["address"], '04X')))

mem_hex.close()
mem_layout.close()