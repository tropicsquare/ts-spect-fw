#!/usr/bin/env python3
import sys
import random as rn
import os

import test_common as tc
import models.p256 as p256
import models.ed25519 as ed25519
import models.x25519 as x25519

TS_REPO_ROOT = os.environ["TS_REPO_ROOT"]

def run_op(cmd_file, cmd_id, test_dir, run_name, break_s=None):
    tc.write_int32(cmd_file, cmd_id, 0x0000)
    tc.run(cmd_file)
    if break_s:
        cmd_file.write(break_s)
    tc.exit(cmd_file)
    cmd_file.close()

    iss = "spect_iss"
    run_log = run_name+"_iss.log"

    hexfile = "build_mpw1/main_mpw1.hex"
    constfile = "data/constants_data_in.hex"
    isa = 1

    cmd = iss
    cmd += f" --instruction-mem={TS_REPO_ROOT}/{hexfile}"
    cmd += f" --isa-version={isa}"
    cmd += f" --first-address=0x8000"
    cmd += f" --const-rom={TS_REPO_ROOT}/{constfile}"
    cmd += f" --data-ram-out={test_dir}/{run_name}_out.hex"
    cmd += f" --shell --cmd-file={test_dir}/iss_cmd"
    cmd += f" > {test_dir}/{run_log}"

    if os.system(cmd):
        print("ISS FAILED")
        sys.exit(2)

if __name__ == "__main__":
    seed = rn.randint(0, 2**32-1)
    rn.seed(seed)
    print("seed:", seed)

    ops_cfg = tc.get_ops_config()
    test_name = "mpw1_test"
    run_name = test_name

    tc.print_run_name(run_name)

    test_dir = tc.make_test_dir(test_name)
    cmd_file = tc.get_cmd_file(test_dir)

    # ECDSA Sign

    d = rn.randint(0, p256.p - 1)
    z = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    k = rn.randint(1, p256.q - 1)

    r_ref, s_ref = p256.sign_mpw1(d, z, k)

    signature_ref = r_ref.to_bytes(32, 'big') + s_ref.to_bytes(32, 'big')

    tc.write_hex(cmd_file, f"{TS_REPO_ROOT}/data/constants_data_in.hex", 0x0200)

    tc.write_int256(cmd_file, d, 0x0020)
    tc.write_bytes(cmd_file, z, 0x0040)
    tc.write_int256(cmd_file, k, 0x0060)

    tc.write_int256(cmd_file, rn.randint(0, 2**256-1), 0x0080)  # t1
    tc.write_int256(cmd_file, rn.randint(0, 2**256-1), 0x00A0)  # t2
    tc.write_int256(cmd_file, rn.randint(0, 2**256-1), 0x00C0)  # t3

    run_op(cmd_file, 0xA1, test_dir, run_name)

    ret_val = tc.read_output(test_dir, run_name, 0x1000, 1)
    signature = tc.read_output(test_dir, run_name, 0x1020, 16, string=True)

    #print(signature_ref.hex())
    #print(signature.hex())

    if not(signature_ref == signature):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

    sys.exit(0)
