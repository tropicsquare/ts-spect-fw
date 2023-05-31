import yaml
import binascii
import os


TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]
OPS_CONFIG = TS_REPO_ROOT+"/spect_fw/spect_ops_config.yml"

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
    cmd_file = open(test_dir+"/iss_cmd", 'w')
    return cmd_file, test_dir

def start(cmd_file):
    cmd_file.write("start\n")

def run(cmd_file):
    cmd_file.write("run\n")

def exit(cmd_file):
    cmd_file.write("exit\n")

def set_op(cmd_file, op):
    cmd_file.write("set mem[0x0000] 0x{}\n".format(format(op["id"], '08X')))

def write_string(cmd_file, s: str, addr):
    val = str2int32(s)
    for w in range(len(val)):
        cmd_file.write("set mem[0x{}] 0x{}\n".format(format(addr+(w*4), '04X'), format(val[w], '08X')))


def run_op(cmd_file, op_name, ops_cfg):
    op = find_in_list(op_name, ops_cfg)
    set_op(cmd_file, op)

    #in_name = op_name + ".yml"
    #with open(in_name, 'r') as in_file:
    #    inputs = yaml.safe_load(in_file)
#
    #if inputs != None:
    #    for input in inputs:
    #        addr = find_in_list(input["name"], op["input"])["address"]
    #        val = str2int32(input["value"])
    #        for w in range(len(val)):
    #            cmd_file.write("set mem[0x{}] 0x{}\n".format(format(addr+(w*4), '04X'), format(val[w], '08X')))

    run(cmd_file)

def run_test(test_dir):
    fw_dir = TS_REPO_ROOT + "/spect_fw"
    iss = TS_REPO_ROOT + "/compiler/build/src/apps/spect_iss"

    cmd = iss
    cmd += f" --instruction-mem={fw_dir}/main.hex"
    cmd += f" --first-address=0x8000"
    cmd += f" --const-rom={fw_dir}/data/const_rom.hex"
    cmd += f" --grv-hex={fw_dir}/data/grv.hex"
    cmd += f" --data-ram-out={test_dir}/out.hex"
    cmd += f" --shell --cmd-file={test_dir}/iss_cmd > {test_dir}/iss.log"

    print("Running command:")
    print(cmd)

    os.system(cmd)
