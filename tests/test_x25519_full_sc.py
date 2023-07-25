#!/usr/bin/env python3
import sys
import random as rn
import numpy as np

import test_common as tc

import models.random_point_generate_25519_model as rpg
import models.x25519

if __name__ == "__main__":

    ops_cfg = tc.get_ops_config()
    test_name = "x25519_full_sc"

    test_dir = tc.make_test_dir(test_name)

    # calculate ehpub and ehpriv
    ehpriv = rn.randint(0, 2**256-1)
    ehpriv_scalar = models.x25519.int2scalar(ehpriv)
    ehpub = models.x25519.x25519(ehpriv_scalar, 9)

    # calculate shpub and shpriv
    shpriv = rn.randint(0, 2**256-1)
    shpriv_scalar = models.x25519.int2scalar(ehpriv)
    shpub = models.x25519.x25519(shpriv_scalar, 9)

    # calculate stpub a stpriv
    stpriv = rn.randint(0, 2**256-1)
    stpriv_scalar = models.x25519.int2scalar(stpriv)
    stpub = models.x25519.x25519(stpriv_scalar, 9)

    #print("ehpriv:", hex(ehpriv))
    #print("ehpub:", hex(ehpub))
    #print("shpriv:", hex(shpriv))
    #print("shpub:", hex(shpub))
    #print("stpriv:", hex(stpriv))
    #print("stpub:", hex(stpub))

# ===================================================================================
#   x25519_kpair_gen
# ===================================================================================
    tc.print_run_name("x25519_kpair_gen")
    cmd_file = tc.get_cmd_file(test_dir)
    rng = [rn.randint(0, 2**256-1) for i in range(8)]
    tc.set_rng(test_dir, rng)
    tc.start(cmd_file)

    etpriv = rng[0]
    etpriv_scalar = models.x25519.int2scalar(etpriv)

    etpub_ref = models.x25519.x25519(etpriv_scalar, 9)

    ctx = tc.run_op(cmd_file, "x25519_kpair_gen", 0x0, 0x1, 0, ops_cfg, test_dir)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, "x25519_kpair_gen")
    
    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    etpub = tc.read_output(test_dir, "x25519_kpair_gen", 0x1020, SPECT_OP_DATA_OUT_SIZE//4)

    if (not(etpub_ref == etpub)):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

# ===================================================================================
#   x25519_sc_et_eh
# ===================================================================================
    tc.print_run_name("x25519_sc_et_eh")
    cmd_file = tc.get_cmd_file(test_dir)
    rng = [rn.randint(0, 2**256-1) for i in range(8)]
    tc.set_rng(test_dir, rng)
    tc.start(cmd_file)

    X1_ref = models.x25519.x25519(etpriv_scalar, ehpub)

    tc.write_int256(cmd_file, ehpub, 0x0020)

    ctx = tc.run_op(cmd_file, "x25519_sc_et_eh", 0x0, 0x1, 32, ops_cfg, test_dir, old_context=ctx)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, "x25519_sc_et_eh")

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    X1 = tc.read_output(test_dir, "x25519_sc_et_eh", 0x1020, SPECT_OP_DATA_OUT_SIZE//4)

    if (not(X1_ref == X1)):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

# ===================================================================================
#   x25519_sc_et_sh
# ===================================================================================
    tc.print_run_name("x25519_sc_et_sh")
    cmd_file = tc.get_cmd_file(test_dir)
    rng = [rn.randint(0, 2**256-1) for i in range(8)]
    tc.set_rng(test_dir, rng)
    tc.start(cmd_file)

    R2_ref = models.x25519.x25519(etpriv_scalar, shpub)

    slot = rn.randint(0, 3)
    tc.set_key(cmd_file, key=shpub, ktype=0x02, slot=slot, offset=0)

    tc.write_int32(cmd_file, slot, 0x0020)

    ctx = tc.run_op(cmd_file, "x25519_sc_et_sh", 0x0, 0x1, 1, ops_cfg, test_dir, old_context=ctx)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, "x25519_sc_et_sh")

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    R2 = tc.read_output(test_dir, "x25519_sc_et_sh", 0x1020, SPECT_OP_DATA_OUT_SIZE//4)

    if (not(R2_ref == R2)):
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()

# ===================================================================================
#   x25519_sc_st_eh
# ===================================================================================
    tc.print_run_name("x25519_sc_st_eh")
    cmd_file = tc.get_cmd_file(test_dir)
    rng = [rn.randint(0, 2**256-1) for i in range(8)]
    tc.set_rng(test_dir, rng)
    tc.start(cmd_file)

    R3_ref = models.x25519.x25519(stpriv_scalar, ehpub)

    tc.set_key(cmd_file, key=stpriv, ktype=0x00, slot=0, offset=0)

    ctx = tc.run_op(cmd_file, "x25519_sc_st_eh", 0x0, 0x1, 1, ops_cfg, test_dir, old_context=ctx)

    SPECT_OP_STATUS, SPECT_OP_DATA_OUT_SIZE = tc.get_res_word(test_dir, "x25519_sc_st_eh")

    if (SPECT_OP_STATUS):
        print("SPECT_OP_STATUS:", hex(SPECT_OP_STATUS))
        tc.print_failed()
        sys.exit(1)

    R3 = tc.read_output(test_dir, "x25519_sc_st_eh", 0x1020, SPECT_OP_DATA_OUT_SIZE//4)

    if (not(R3_ref == R3)):
        print(hex(R3_ref))
        print(hex(R2))
        tc.print_failed()
        sys.exit(1)

    tc.print_passed()
    sys.exit(0)
