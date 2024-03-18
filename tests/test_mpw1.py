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
    tc.write_hex(cmd_file, f"{TS_REPO_ROOT}/build_mpw1/constants.hex", 0x0200)
    tc.run(cmd_file)
    if break_s:
        cmd_file.write(break_s)
    tc.exit(cmd_file)
    cmd_file.close()

    iss = "spect_iss"
    run_log = run_name+"_iss.log"

    main = "src/mpw1/main_mpw1.s"
    print(f"Source: {main}")

    #constfile = "data/constants_data_in.hex"
    isa = 1

    cmd = iss
    cmd += f" --program={TS_REPO_ROOT}/{main}"
    cmd += f" --isa-version={isa}"
    cmd += f" --first-address=0x8000"
    #cmd += f" --const-rom={TS_REPO_ROOT}/{constfile}"
    cmd += f" --data-ram-out={test_dir}/{run_name}_out.hex"
    cmd += f" --shell --cmd-file={test_dir}/iss_cmd"
    cmd += f" > {test_dir}/{run_log}"

    if os.system(cmd):
        print("ISS FAILED")
        sys.exit(2)

if __name__ == "__main__":
    exit_val = 0

    args = tc.parser.parse_args()
    seed = tc.set_seed(args)
    rn.seed(seed)
    print("seed:", seed)

    test_name = "mpw1_test"
    test_dir = tc.make_test_dir(test_name)

    ##############################################################################
    #   ECDSA
    ##############################################################################

    run_name = test_name + "_ecdsa"

    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    d = rn.randint(0, p256.p - 1)
    z = int.to_bytes(rn.randint(0, 2**256-1), 32, 'big')
    k = rn.randint(1, p256.q - 1)

    r_ref, s_ref = p256.sign_mpw1(d, z, k)

    signature_ref = r_ref.to_bytes(32, 'big') + s_ref.to_bytes(32, 'big')

    tc.write_int256(cmd_file, d, 0x0020)
    tc.write_bytes(cmd_file, z, 0x0040)
    tc.write_int256(cmd_file, k, 0x0060)

    tc.write_int256(cmd_file, rn.randint(0, 2**256-1), 0x0080)  # t1
    tc.write_int256(cmd_file, rn.randint(0, 2**256-1), 0x00A0)  # t2
    tc.write_int256(cmd_file, rn.randint(0, 2**256-1), 0x00C0)  # t3

    run_op(cmd_file, 0xA1, test_dir, run_name)

    ret_val = tc.read_output(test_dir, run_name, 0x1000, 1)
    signature = tc.read_output(test_dir, run_name, 0x1020, 16, string=True)    

    if not(signature_ref == signature):
        print("RET_VAL: ", hex(ret_val))
        print(signature_ref.hex())
        print(signature.hex())
        tc.print_failed()
        exit_val += 1
    else:
        tc.print_passed()

    ##############################################################################
    #   P-256 SPM
    ##############################################################################
    # NONMASKED ##################################################################

    run_name = test_name + "_scm_p256_nonmasked"

    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    k = rn.randint(0, 2**256 - 1)
    Px, Py = p256.spm(rn.randint(0, p256.q - 1), p256.xG, p256.yG)

    Qx_ref, Qy_ref = p256.spm(k, Px, Py)

    tc.write_int256(cmd_file, k,  0x0020)
    tc.write_int256(cmd_file, Px, 0x0040)
    tc.write_int256(cmd_file, Py, 0x0060)

    run_op(cmd_file, 0xB1, test_dir, run_name)

    ret_val = tc.read_output(test_dir, run_name, 0x1000, 1)
    Qx = tc.read_output(test_dir, run_name, 0x1040, 8)
    Qy = tc.read_output(test_dir, run_name, 0x1060, 8)

    if not(Qx == Qx_ref and Qy == Qy_ref):
        print("RET_VAL: ", hex(ret_val))
        print("ref x: ", hex(Qx_ref))
        print("ref y: ", hex(Qy_ref))
        print("")
        print("    x: ", hex(Qx))
        print("    y: ", hex(Qy))
        tc.print_failed()
        exit_val += 1
    else:
        tc.print_passed()

    # MASKED #####################################################################

    run_name = test_name + "_scm_p256_masked"

    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    tc.write_int256(cmd_file, k,  0x0020)
    tc.write_int256(cmd_file, Px, 0x0040)
    tc.write_int256(cmd_file, Py, 0x0060)

    t1 = rn.randint(1, 2**256-1)
    t2 = rn.randint(0, 2**256-1)

    tc.write_int256(cmd_file, t1, 0x0080)
    tc.write_int256(cmd_file, t2, 0x00A0)

    run_op(cmd_file, 0xB2, test_dir, run_name)

    ret_val = tc.read_output(test_dir, run_name, 0x1000, 1)
    Qx = tc.read_output(test_dir, run_name, 0x1040, 8)
    Qy = tc.read_output(test_dir, run_name, 0x1060, 8)

    if not(Qx == Qx_ref and Qy == Qy_ref):
        print("RET_VAL: ", hex(ret_val))
        print("ref x: ", hex(Qx_ref))
        print("ref y: ", hex(Qy_ref))
        print("")
        print("    x: ", hex(Qx))
        print("    y: ", hex(Qy))
        tc.print_failed()
        exit_val += 1
    else:
        tc.print_passed()

    ##############################################################################
    #   Ed25519 SPM
    ##############################################################################
    # NONMASKED ##################################################################

    run_name = test_name + "_scm_ed25519_nonmasked"

    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    k = rn.randint(0, 2**256-1)
    P = ed25519.point_mul(rn.randint(0, 2**256-1), ed25519.G)
    zinv = ed25519.modp_inv(P[2])
    Px = P[0] * zinv % ed25519.p
    Py = P[1] * zinv % ed25519.p

    Q = ed25519.point_mul(k, P)
    zinv = ed25519.modp_inv(Q[2])
    Qx_ref = Q[0] * zinv % ed25519.p
    Qy_ref = Q[1] * zinv % ed25519.p

    tc.write_int256(cmd_file, k,  0x0020)
    tc.write_int256(cmd_file, Px, 0x0040)
    tc.write_int256(cmd_file, Py, 0x0060)

    run_op(cmd_file, 0xC1, test_dir, run_name)

    ret_val = tc.read_output(test_dir, run_name, 0x1000, 1)
    Qx = tc.read_output(test_dir, run_name, 0x1040, 8)
    Qy = tc.read_output(test_dir, run_name, 0x1060, 8)

    if not(Qx == Qx_ref and Qy == Qy_ref):
        print("RET_VAL: ", hex(ret_val))
        print("ref x: ", hex(Qx_ref))
        print("ref y: ", hex(Qy_ref))
        print("")
        print("    x: ", hex(Qx))
        print("    y: ", hex(Qy))
        tc.print_failed()
        exit_val += 1
    else:
        tc.print_passed()

    # MASKED #####################################################################

    run_name = test_name + "_scm_ed25519_masked"

    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    tc.write_int256(cmd_file, k,  0x0020)
    tc.write_int256(cmd_file, Px, 0x0040)
    tc.write_int256(cmd_file, Py, 0x0060)

    t1 = rn.randint(1, 2**256-1)
    t2 = rn.randint(0, 2**256-1)

    tc.write_int256(cmd_file, t1, 0x0080)
    tc.write_int256(cmd_file, t2, 0x00A0)

    run_op(cmd_file, 0xC2, test_dir, run_name)

    ret_val = tc.read_output(test_dir, run_name, 0x1000, 1)
    Qx = tc.read_output(test_dir, run_name, 0x1040, 8)
    Qy = tc.read_output(test_dir, run_name, 0x1060, 8)

    if not(Qx == Qx_ref and Qy == Qy_ref):
        print("RET_VAL: ", hex(ret_val))
        print("ref x: ", hex(Qx_ref))
        print("ref y: ", hex(Qy_ref))
        print("")
        print("    x: ", hex(Qx))
        print("    y: ", hex(Qy))
        tc.print_failed()
        exit_val += 1
    else:
        tc.print_passed()

    ##############################################################################
    #   X25519
    ##############################################################################
    # NONMASKED ##################################################################
    run_name = test_name + "_x25519_nonmasked"

    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    k = rn.randint(0, 2**256-1)
    u = x25519.x25519(x25519.int2scalar(rn.randint(0, 2**256-1)), 9)

    k_scalar = x25519.int2scalar(k)
    x_ref = x25519.x25519(k_scalar, u)

    tc.write_int256(cmd_file, k,  0x0020)
    tc.write_int256(cmd_file, u,  0x0040)

    run_op(cmd_file, 0xD1, test_dir, run_name)

    ret_val = tc.read_output(test_dir, run_name, 0x1000, 1)

    x = tc.read_output(test_dir, run_name, 0x1040, 8)

    if not(x == x_ref):
        print("RET_VAL: ", hex(ret_val))
        print("ref x: ", hex(x_ref))
        print("    x: ", hex(x))
        tc.print_failed()
        exit_val += 1
    else:
        tc.print_passed()

    # MASKED #####################################################################
    run_name = test_name + "_x25519_masked"

    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    tc.write_int256(cmd_file, k,  0x0020)
    tc.write_int256(cmd_file, u,  0x0040)

    t1 = rn.randint(1, 2**256-1)
    t2 = rn.randint(0, 2**256-1)

    tc.write_int256(cmd_file, t1, 0x0080)
    tc.write_int256(cmd_file, t2, 0x00A0)

    run_op(cmd_file, 0xD2, test_dir, run_name)

    ret_val = tc.read_output(test_dir, run_name, 0x1000, 1)

    x = tc.read_output(test_dir, run_name, 0x1040, 8)

    if not(x == x_ref):
        print("RET_VAL: ", hex(ret_val))
        print("ref x: ", hex(x_ref))
        print("    x: ", hex(x))
        tc.print_failed()
        exit_val += 1
    else:
        tc.print_passed()


    sys.exit(exit_val)
