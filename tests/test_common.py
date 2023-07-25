import yaml
import binascii
import os
import sys
import numpy as np

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]
OPS_CONFIG = TS_REPO_ROOT+"/spect_ops_config.yml"

def print_passed():
    print("\033[92m{}\033[00m".format("PASSED"))

def print_failed():
    print("\033[91m{}\033[00m".format("FAILED"))

def print_run_name(run_name: str):
    print("\033[94m{}\033[00m".format(f"running {run_name}"))

def find_in_list (name: str, l: list) -> dict:
    for item in l:
        if item["name"] == name:
            return item
    return None

def str2int32 (in_str: str) -> list:
    r = []
    for w in range(0, len(in_str), 8):
        w_str = in_str[w:w+8]
        r.append(int.from_bytes(binascii.unhexlify(w_str), 'little'))
    return r

def get_ops_config():
    with open(OPS_CONFIG, 'r') as ca_file:
        ops_cfg = yaml.safe_load(ca_file)
    return ops_cfg

def make_test_dir(test_name):
    test_dir = TS_REPO_ROOT+"/tests/test_"+test_name
    os.system(f"rm -rf {test_dir}")
    os.system(f"mkdir {test_dir}")
    return test_dir

def get_cmd_file(test_dir):
    cmd_file = open(test_dir+"/iss_cmd", 'w')
    return cmd_file

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
    SPECT_OP_DATA_OUT_SIZE = (res_word >> 16) & 0xFF
    return SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE

def parse_key_mem(test_dir, run_name):
    kmem_file = f"{test_dir}/{run_name}_keymem.hex"
    kmem_array = np.empty(shape=(16, 256, 256), dtype='uint32')
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
            d = int.from_bytes(binascii.unhexlify(line), 'big')
            kmem_array[ktype][slot][offset] = d
            offset += 1
    return kmem_array

def set_key(cmd_file, key, ktype, slot, offset):
    val = [(key >> i*32) & 0xFFFFFFFF for i in range(8)]
    for w in range(len(val)):
        cmd_file.write("set keymem[{}][{}][{}] {}\n".format(ktype, slot, offset+w, val[w]))

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

def break_on(cmd_file, bp):
    cmd_file.write(f"break {bp}\n")

def write_string(cmd_file, s: str, addr):
    val = str2int32(s)
    for w in range(len(val)):
        write_int32(cmd_file, val[w], addr+(w*4))

def write_bytes(cmd_file, b: bytes, addr):
    write_string(cmd_file, b.hex(), addr)

def set_rng(test_dir: str, rng: list):
    with open(f"{test_dir}/rng.hex", mode='w') as rng_hex:
        for r in rng:
            for i in range(8):
                rng_hex.write(format((r >> i*32) & 0xffffffff, '08X') + "\n")

def read_output(test_dir: str, run_name: str, addr: int, count: int) -> int:
    mem = addr & 0xF000
    if mem == 0x1000:
        output_file = f"{test_dir}/{run_name}_out.hex"
    elif mem == 0x5000:
        output_file = f"{test_dir}/{run_name}_emem_out.hex"
    else:
        raise Exception(f"Address {addr} is invalid output address!")

    with open(output_file, mode='r') as out:
        data = out.read().split('\n')
        idx = (addr - mem) // 4
        val = 0
        for i in range(count):
            val += int.from_bytes(binascii.unhexlify(data[idx+i].split(' ')[1]), 'big') << i*32
        return val
    
def run_op(cmd_file, op_name, insrc, outsrc, data_in_size, ops_cfg, test_dir, run_name=None, old_context=None, keymem=None):
    op = find_in_list(op_name, ops_cfg)
    cfg_word = op["id"] + (outsrc << 8) + (insrc << 12) + (data_in_size << 16)
    set_cfg_word(cmd_file, cfg_word)
    run(cmd_file)
    exit(cmd_file)
    cmd_file.close()

    iss = "spect_iss"
    if not run_name:
        run_name = op_name
    new_context = run_name+".ctx"
    run_log = run_name+"_iss.log"

    cmd = iss
    cmd += f" --instruction-mem={TS_REPO_ROOT}/build/main.hex"
    cmd += f" --first-address=0x8000"
    cmd += f" --const-rom={TS_REPO_ROOT}/data/const_rom.hex"
    cmd += f" --grv-hex={test_dir}/rng.hex"
    cmd += f" --data-ram-out={test_dir}/{run_name}_out.hex"
    cmd += f" --emem-out={test_dir}/{run_name}_emem_out.hex"
    cmd += f" --dump-keymem={test_dir}/{run_name}_keymem.hex"
    if keymem:
        cmd += f" --load-keymem={keymem}"
    if old_context:
        cmd += f" --load-context={test_dir}/{old_context}"
    cmd += f" --dump-context={test_dir}/{new_context}"
    #cmd += f" --isa-version=1"
    cmd += f" --shell --cmd-file={test_dir}/iss_cmd > {test_dir}/{run_log}"

    if os.system(cmd):
        print("ISS FAILED")
        sys.exit(2)

    return new_context
