import yaml
import binascii
import os
import sys

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]
OPS_CONFIG = TS_REPO_ROOT+"/spect_fw/spect_ops_config.yml"

def print_passed():
    print("\033[92m{}\033[00m".format("PASSED"))

def print_failed():
    print("\033[91m{}\033[00m".format("FAILED"))

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
    test_dir = TS_REPO_ROOT+"/spect_fw/tests/test_"+test_name
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

def get_res_word(test_dir, test_name):
    res_word = read_output(f"{test_dir}/{test_name}_out.hex", 0x1100, 1)
    SPECT_OP_STATUS = res_word & 0xFF
    SPECT_OP_DATA_OUT_SIZE = (res_word >> 16) & 0xFF
    return SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE


def break_on(cmd_file, bp):
    cmd_file.write(f"break {bp}\n")

def write_int32(cmd_file, x: int, addr):
    cmd_file.write("set mem[0x{}] 0x{}\n".format(format(addr, '04X'), format(x, '08X')))

def break_on(cmd_file, bp):
    cmd_file.write(f"break {bp}\n")

def write_int32(cmd_file, x: int, addr):
    cmd_file.write("set mem[0x{}] 0x{}\n".format(format(addr, '04X'), format(x, '08X')))

def write_string(cmd_file, s: str, addr):
    val = str2int32(s)
    for w in range(len(val)):
        write_int32(cmd_file, val[w], addr+(w*4))

def set_rng(test_dir: str, rng: list):
    with open(f"{test_dir}/rng.hex", mode='w') as rng_hex:
        for r in rng:
            for i in range(8):
                rng_hex.write(format((r >> i*32) & 0xffffffff, '08X') + "\n")

def read_output(output_file: str, addr: int, count: int) -> int:
    with open(output_file, mode='r') as out:
        data = out.read().split('\n')
        idx = (addr - 0x1000) // 4
        val = 0
        for i in range(count):
            val += int.from_bytes(binascii.unhexlify(data[idx+i].split(' ')[1]), 'big') << i*32
        return val
    
def run_op(cmd_file, op_name, insrc, outsrc, data_in_size, ops_cfg, test_dir, run_id=-1, old_context=None):
    op = find_in_list(op_name, ops_cfg)
    cfg_word = op["id"] + (outsrc << 8) + (insrc << 12) + (data_in_size << 16)
    set_cfg_word(cmd_file, cfg_word)
    run(cmd_file)
    exit(cmd_file)
    cmd_file.close()

    fw_dir = TS_REPO_ROOT + "/spect_fw"
    iss = TS_REPO_ROOT + "/compiler/build/src/apps/spect_iss"
    run_name = op_name
    if run_id >= 0:
        run_name += f"_{run_id}"
    new_context = run_name+".ctx"
    run_log = run_name+"_iss.log"

    print(f"running {run_name}")

    cmd = iss
    cmd += f" --program={fw_dir}/src/main.s"
    cmd += f" --first-address=0x8000"
    cmd += f" --const-rom={fw_dir}/data/const_rom.hex"
    cmd += f" --grv-hex={test_dir}/rng.hex"
    cmd += f" --data-ram-out={test_dir}/{run_name}_out.hex"
    if old_context:
        cmd += f" --load-context={test_dir}/{old_context}"
    cmd += f" --dump-context={test_dir}/{new_context}"
    #cmd += f" --isa-version=1"
    cmd += f" --shell --cmd-file={test_dir}/iss_cmd > {test_dir}/{run_log}"

    if os.system(cmd):
        print("ISS FAILED")
        sys.exit(2)

    return new_context
