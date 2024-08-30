import yaml
import binascii
import os
import sys
import numpy as np
import random as rn
import subprocess
import re
from argparse import SUPPRESS, ArgumentParser

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]
OPS_CONFIG = TS_REPO_ROOT+"/spect_ops_config.yml"

Ed25519_ID = 0x02
P256_ID = 0x01

RAR_STACK_DEPTH = 5
DATA_RAM_IN_DEPTH = 512
DATA_RAM_OUT_DEPTH = 128

SHA_CTX_INIT = binascii.unhexlify("6a09e667f3bcc908bb67ae8584caa73b3c6ef372fe94f82ba54ff53a5f1d36f1510e527fade682d19b05688c2b3e6c1f1f83d9abfb41bd6b5be0cd19137e2179")

insrc_arr = [0x0, 0x4]
outsrc_arr = [0x1, 0x5]

fw_parity = 2

#############################################################
#   PARSER
#############################################################
parser = ArgumentParser(description='TS SPECT tests scripts')

parser.add_argument(
    "--testvec",
    default="",
    help='Test Vector input file name. Optional'
)

parser.add_argument(
    "--seed",
    type=int,
    default=SUPPRESS,
    help="Seed for randomization. Optional"
)

##################################################################
#   RNG LUTs
##################################################################
rng_luts = {
    "x25519_dbg" : {
        "pub_z_rng"     : 0,
        "s_rng_1"       : 1,
        "point_gen_rng" : 2,
        "s_rng_2"       : 3
    },
    "ecdsa_sign_dbg" : {
        "base_z_rng"    : 4,
        "point_gen_rng" : 5,
        "s_rng_1"       : 6,
        "s_rng_2"       : 7,
        "t_rng"         : 8
    }
}
##################################################################

def get_release_version():
    try:
        result = subprocess.run(
            ['git', 'describe', '--dirty'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        if result.returncode == 0:
            output = result.stdout.strip()
            return output
        else:
            print("Error running 'git describe --dirty':", result.stderr.strip())
            return None

    except FileNotFoundError:
        print("Git command not found. Make sure Git is installed.")
        return None

def get_released_file(prefix):
    suffix = ".hex"
    pattern = re.compile(f"{re.escape(prefix)}(.*){re.escape(suffix)}$")

    matching_files = []
    for filename in os.listdir(f"{TS_REPO_ROOT}/release"):
        match = pattern.match(filename)
        if match:
            extracted_part = match.group(1)
            matching_files.append((filename, extracted_part))

    if len(matching_files) > 1:
        print(f"Found more than one file of type \'{prefix}*.hex\'!")
    
    return matching_files[0]

def print_passed():
    print("\033[92m{}\033[00m".format("PASSED"))

def print_failed():
    print("\033[91m{}\033[00m".format("FAILED"))

def print_warning(text):
    print("\033[93mWarning: {}\033[00m".format(text))

def print_run_name(run_name: str):
    print("\033[94m{}\033[00m".format(f"running {run_name}"))

def find_in_list (name: str, l: list) -> dict:
    for item in l:
        if item["name"] == name:
            return item
    return None

def str2int (in_str: str, endian: str) -> int:
    return int.from_bytes(binascii.unhexlify(in_str), endian)

def str2int32 (in_str: str) -> list:
    r = []
    for w in range(0, len(in_str), 8):
        w_str = in_str[w:w+8]
        r.append(str2int(w_str, 'little'))
    return r

def get_ops_config():
    with open(OPS_CONFIG, 'r') as ca_file:
        ops_cfg = yaml.safe_load(ca_file)
    return ops_cfg

def get_data_cfg(run_name):
    ops_cfg = get_ops_config()
    cmd_cfg = find_in_list(run_name, ops_cfg)
    with open(f"{run_name}_data_cfg.yml", 'r') as data_file:
        data_cfg = yaml.safe_load(data_file)
    return cmd_cfg, data_cfg

def make_test_dir(test_name, directory = "tests"):
    test_dir = f"{TS_REPO_ROOT}/{directory}/test_{test_name}"
    os.system(f"rm -rf {test_dir}")
    os.system(f"mkdir {test_dir}")
    return test_dir

def get_cmd_file(test_dir):
    cmd_file = open(test_dir+"/iss_cmd", 'w')
    return cmd_file

def gpr_preload(cmd_file):
    for i in range(32):
        cmd_file.write(f"set R{i} {rn.randint(0, 2**256 -1)}\n")

def start(cmd_file):
    cmd_file.write("start\n")

def run(cmd_file):
    cmd_file.write("run\n")

def exit(cmd_file):
    cmd_file.write("exit\n")

def set_cfg_word(cmd_file, cfg_word):
    cmd_file.write("set mem[0x0100] 0x{}\n".format(format(cfg_word, '08X')))

def get_res_word(test_dir, run_name):
    res_word = read_output(test_dir, run_name, 0x1100, 1)
    SPECT_OP_STATUS = res_word & 0xFF
    SPECT_OP_DATA_OUT_SIZE = (res_word >> 16) & 0xFFFF
    return SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE

def parse_context(test_dir, run_name):
    ctx_file = f"{test_dir}/{run_name}.ctx"
    ctx_dict = {
        "GPR"           : [],
        "SHA"           : b'',
        "TMAC"          : b'',
        "RAR STACK"     : [],
        "RAR POINTER"   : 0,
        "FLAGS"         : {"Z" : 0, "C" : 0, "E" : 0},
        "DATA RAM IN"   : [],
        "DATA RAM OUT"  : []
    }

    with open(ctx_file, 'r') as ctx:
        data = ctx.read().split('\n')
        for i in range(len(data)):
            line = data[i]
            if not line:
                continue
            if line[0] == "*":
                continue
            
            if line == "GPR registers:":
                i += 1  # skip next "**..**" line
                for j in range(32):
                    i += 1
                    line = data[i]
                    r = int.from_bytes(binascii.unhexlify(line), 'big')
                    ctx_dict["GPR"].append(r)
            
            if line == "SHA 512 context:":
                i += 1  # skip next "**..**" line
                for j in range(8):
                    i += 1
                    line = data[i]
                    ctx_dict["SHA"] += binascii.unhexlify(line)
                continue
                
            if line[:4] == "TMAC":
                i += 1
                for j in range(5):
                    i += 1
                    line = data[i]
                    ctx_dict["TMAC"] += binascii.unhexlify(line)
                i += 3  # skip rate, byteIOIndex and squeezing
                continue
            
            if line == "RAR stack:":
                i += 1  # skip next "**..**" line
                for j in range(RAR_STACK_DEPTH):
                    i +=1
                    line = data[i]
                    val = int.from_bytes(binascii.unhexlify(line), 'big')
                    ctx_dict["RAR STACK"].append(val)
                continue
            if line == "RAR stack pointer:":
                i += 2
                line = data[i]
                ctx_dict["RAR POINTER"] = int.from_bytes(binascii.unhexlify(line), 'big')
                continue

            if line == "FLAGS (Z, C, E):":
                i += 2
                line = data[i]
                ctx_dict["FLAGS"]["Z"] = int(line)
                i += 1
                line = data[i]
                ctx_dict["FLAGS"]["C"] = int(line)
                i += 1
                line = data[i]
                ctx_dict["FLAGS"]["E"] = int(line)
                continue

            if line == "Data RAM In:":
                i += 1
                for j in range(DATA_RAM_IN_DEPTH):
                    i += 1
                    line = data[i]
                    val = int.from_bytes(binascii.unhexlify(line), 'big')
                    ctx_dict["DATA RAM IN"].append(val)

            if line == "Data RAM Out:":
                i += 1
                for j in range(DATA_RAM_OUT_DEPTH):
                    i += 1
                    line = data[i]
                    val = int.from_bytes(binascii.unhexlify(line), 'big')
                    ctx_dict["DATA RAM OUT"].append(val)

    return ctx_dict

def parse_key_mem(test_dir, run_name):
    kmem_file = f"{test_dir}/{run_name}_keymem.hex"
    kmem_array = np.empty(shape=(16, 256, 256), dtype='uint32')
    kmem_slots = np.empty(shape=(16, 256), dtype='bool')
    with open(kmem_file, 'r') as km_file:
        data = km_file.read().split('\n')
        ktype = 0
        slot = 0
        offset = 0
        for line in data[3:]:
            if not line:
                continue
            if line[0] == '*':
                continue
            if line[0] == 'T':
                ls = line.split(' ')
                ktype = int(ls[1])
                slot = int(ls[3])
                offset = 0
                continue
            if line[0] == 'S':
                ls = line.split(' ')
                if ls[1] == "FULL":
                    kmem_slots[ktype][slot] = True
                else:
                    kmem_slots[ktype][slot] = False
                continue
            d = int.from_bytes(binascii.unhexlify(line), 'big')
            kmem_array[ktype][slot][offset] = d
            offset += 1
    return kmem_array, kmem_slots

def parse_testvec(testvec_file: str, rng_lut):
    with open(testvec_file, 'r') as f:
        testvec = yaml.safe_load(f)

    data_dir = {}
    for input in testvec["input"]:
        data_dir[input["name"]] = input["value"]

    rng_list = [rn.randint(0, 2**256 - 1) for i in range(4*len(rng_lut))]
    if "rng" in testvec.keys():
        for rng in testvec["rng"]:
            idx = rng_lut[rng["name"]]
            if rng["value"] is not None:
                rng_list[idx] = rng["value"]
    return data_dir, rng_list

def set_seed(args) -> int:
    if hasattr(args, "seed"):
        return args.seed
    else:
        return rn.randint(0, 2**32-1)

def set_key(cmd_file, key, ktype, slot, offset):
    val = [(key >> i*32) & 0xFFFFFFFF for i in range(8)]
    for w in range(len(val)):
        cmd_file.write("set keymem[{}][{}][{}] 0x{}\n".format(ktype, slot, offset+w, format(val[w], '08X')))

def get_key(kmem_array, ktype, slot, offset) -> int:
    val = 0
    for i in range(8):
        w = kmem_array[ktype][slot][offset+i]
        val += (int(w) << (i*32))
    return val

def break_on(cmd_file, bp):
    cmd_file.write(f"break {bp}\n")

def write_int32(cmd_file, x: int, addr):
    cmd_file.write("set mem[0x{}] 0x{}\n".format(format(addr, '04X'), format(x, '08X')))

def write_int256(cmd_file, x: int, addr):
    val = [(x >> i*32) & 0xFFFFFFFF for i in range(8)]
    for w in range(len(val)):
        write_int32(cmd_file, val[w], addr+(w*4))

def dump_gpr_on(cmd_file, bp, gpr: list) -> str:
    cmd_file.write(f"break {bp}\n")
    s = ""
    for r in gpr:
        s += f"get R{r}\n"
    s += "run\n"
    return s

def write_string(cmd_file, s: str, addr):
    val = str2int32(s)
    for w in range(len(val)):
        write_int32(cmd_file, val[w], addr+(w*4))

def write_bytes(cmd_file, b: bytes, addr):
    write_string(cmd_file, b.hex(), addr)

def write_hex(cmd_file, hex_file_name, start_addr):
    with open(hex_file_name, 'r') as hex_file:
        for line in hex_file:
            line = line.strip()
            if not line:
                continue
            write_int32(cmd_file, int(line, 16), start_addr)
            start_addr += 4

def set_rng(test_dir: str, rng: list):
    with open(f"{test_dir}/rng.hex", mode='w') as rng_hex:
        for r in rng:
            for i in range(8):
                rng_hex.write(format((r >> i*32) & 0xffffffff, '08X') + "\n")

def read_output(test_dir: str, run_name: str, addr: int, count: int, string=False):
    mem = addr & 0xF000
    if mem == 0x1000:
        output_file = f"{test_dir}/{run_name}_out.hex"
    elif mem == 0x5000:
        output_file = f"{test_dir}/{run_name}_emem_out.hex"
    else:
        raise Exception(f"Address {hex(addr)} is invalid output address!")

    if not string:
        with open(output_file, mode='r') as out:
            data = out.read().split('\n')
            idx = (addr - mem) // 4
            val = 0
            for i in range(count):
                val += int.from_bytes(binascii.unhexlify(data[idx+i].split(' ')[1]), 'big') << i*32
            return val
    else:
        with open(output_file, mode='r') as out:
            data = out.read().split('\n')
            idx = (addr - mem) // 4
            val = b''
            for i in range(count):
                val += int.from_bytes(binascii.unhexlify(data[idx+i].split(' ')[1]), 'little').to_bytes(4, 'big')
            return val
    
def run_op(
            cmd_file,           op_name,
            insrc,              outsrc,         data_in_size,
            ops_cfg,            test_dir,       run_name=None,
            main=None,          isa=2,          tag="Application",
            old_context=None,   keymem=None,    break_s=None
        ):

    op = find_in_list(op_name, ops_cfg)
    cfg_word = op["id"] + (outsrc << 8) + (insrc << 12) + (data_in_size << 16)
    set_cfg_word(cmd_file, cfg_word)
    run(cmd_file)
    if break_s:
        cmd_file.write(break_s)
    exit(cmd_file)
    cmd_file.close()

    iss = "spect_iss"
    if not run_name:
        run_name = op_name
    new_context = run_name+".ctx"
    run_log = run_name+"_iss.log"

    hexfile = "build/main.hex"
    constfile = "build/constants.hex"


    if "TS_SPECT_FW_TEST_RELEASE" in os.environ.keys():
        version = get_release_version()

        release_const = get_released_file("spect_const_rom_code-")
        constfile = f"release/{release_const[0]}"

        if tag == "Boot2":
            prefix = "spect_boot-"
        else: # tag == "Application"
            prefix = "spect_app-"

        release_file = get_released_file(prefix)
        hexfile = f"release/{release_file[0]}"

        if version != release_file[1]:
            print_warning("Running test on release that does not match the current git version.")
            print("Running:", release_file[1])
            print("Current:", version)

        if release_file[1] != release_const[1]:
            print_warning("Release version of FW and Const ROM Code does not match.")
            print("FW:     ", release_file[1])
            print("Const:  ", release_const[1])

    cmd = iss
    
    if ("TS_SPECT_FW_TEST_RELEASE" not in os.environ.keys()) and (break_s or main):
        if not main:
            main = "src/main.s"
        cmd += f" --program={TS_REPO_ROOT}/{main}"
        print(f"Source: {main}")
    else:
        cmd += f" --instruction-mem={TS_REPO_ROOT}/{hexfile}"
        cmd += f" --parity={fw_parity}"
        print(f"Source: {hexfile}")
    cmd += f" --isa-version={isa}"
    cmd += f" --first-address=0x8000"
    if isa == 2:
        print(f"Const: {constfile}")
        cmd += f" --const-rom={TS_REPO_ROOT}/{constfile}"
    cmd += f" --grv-hex={test_dir}/rng.hex"
    cmd += f" --data-ram-out={test_dir}/{run_name}_out.hex"
    cmd += f" --emem-out={test_dir}/{run_name}_emem_out.hex"
    cmd += f" --dump-keymem={test_dir}/{run_name}_keymem.hex"
    cmd += f" --dump-context={test_dir}/{new_context}"
    if keymem:
        cmd += f" --load-keymem={keymem}"
    if old_context:
        cmd += f" --load-context={test_dir}/{old_context}"
    cmd += f" --shell --cmd-file={test_dir}/iss_cmd"
    cmd += f" > {test_dir}/{run_log}"

    if os.system(cmd):
        print("ISS FAILED")
        sys.exit(2)

    return new_context
