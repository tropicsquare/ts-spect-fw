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
mem_leyout_name = os.path.join(os.path.dirname(sys.argv[1]), mem["name"] + "_leyout.s")
print("hexfile -> ", mem_hex_name)
print("leyout -> ", mem_leyout_name)
mem_hex = open(mem_hex_name, "w")
mem_leyout = open(mem_leyout_name, "w")

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

        mem_leyout.write("{} .eq 0x{}\n".format(d["name"], format(d["address"], '04X')))

mem_hex.close()
mem_leyout.close()