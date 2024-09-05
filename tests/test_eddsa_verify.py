#!/usr/bin/env python3
import sys

import test_common as tc

if __name__ == "__main__":

    ops_cfg = tc.get_ops_config()
    test_name = "eddsa_verify"

    test_dir = tc.make_test_dir(test_name)

    ret = 0

    #######################################################################################
    # Valid Signature
    #######################################################################################

    cmd_file = tc.get_cmd_file(test_dir)

    run_name = f"{test_name}_valid"
    tc.print_run_name(run_name)

    R = "2ef9ff1d7926588de9c68104492034a8a8edab57686d95729de313fc70a8623a"
    S = "86031e5bffd2b8fa2b5daf20a09dae43994d209d24042a34ba17cc6cea8ce40f"
    A = "f13c21fd271db83863eab2d4d9a9b503fe745dcb15da3ef5a607a27f7478bbd1"
    M1 = "8f13b3a29344b73d22e681e9faeb3fedb88c94f7504f8f2ac2f17a09fc33a1f6"
    M2 = "b83275219d83def87aa1f74537c8819db6759c80fff5b4c42aa09b663c5304d9"

    tc.start(cmd_file)
    tc.write_string(cmd_file, R, 0x0020)
    tc.write_string(cmd_file, S, 0x0040)
    tc.write_string(cmd_file, A, 0x0060)
    tc.write_string(cmd_file, M1, 0x0080)
    tc.write_string(cmd_file, M2, 0x00A0)
    ctx = tc.run_op(cmd_file, "eddsa_verify", 0x0, 0x1, 160, ops_cfg, test_dir, run_name=run_name)

    res = tc.read_output(test_dir, run_name, 0x1000, 1)

    if res != 1:
        tc.print_failed()
        ret = 1
    else:
        tc.print_passed()

    #######################################################################################
    # Invalid R
    #######################################################################################

    run_name = f"{test_name}_invR"
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    R = "2ef9ff1d7926588de9c68104492034a8a8edab57686d95729de313fc70a8623b"
    S = "86031e5bffd2b8fa2b5daf20a09dae43994d209d24042a34ba17cc6cea8ce40f"
    A = "f13c21fd271db83863eab2d4d9a9b503fe745dcb15da3ef5a607a27f7478bbd1"
    M1 = "8f13b3a29344b73d22e681e9faeb3fedb88c94f7504f8f2ac2f17a09fc33a1f6"
    M2 = "b83275219d83def87aa1f74537c8819db6759c80fff5b4c42aa09b663c5304d9"

    tc.start(cmd_file)
    tc.write_string(cmd_file, R, 0x0020)
    tc.write_string(cmd_file, S, 0x0040)
    tc.write_string(cmd_file, A, 0x0060)
    tc.write_string(cmd_file, M1, 0x0080)
    tc.write_string(cmd_file, M2, 0x00A0)
    ctx = tc.run_op(cmd_file, "eddsa_verify", 0x0, 0x1, 160, ops_cfg, test_dir, run_name=run_name)

    res = tc.read_output(test_dir, run_name, 0x1000, 1)

    if res != 0:
        tc.print_failed()
        ret = 1
    else:
        tc.print_passed()

    #######################################################################################
    # Invalid S
    #######################################################################################

    run_name = f"{test_name}_invS"
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    R = "2ef9ff1d7926588de9c68104492034a8a8edab57686d95729de313fc70a8623a"
    S = "86031e5bffd2b8fa2b5daf20a09dae43994d209d24042a34ba17cc6cea8ce40e"
    A = "f13c21fd271db83863eab2d4d9a9b503fe745dcb15da3ef5a607a27f7478bbd1"
    M1 = "8f13b3a29344b73d22e681e9faeb3fedb88c94f7504f8f2ac2f17a09fc33a1f6"
    M2 = "b83275219d83def87aa1f74537c8819db6759c80fff5b4c42aa09b663c5304d9"

    tc.start(cmd_file)
    tc.write_string(cmd_file, R, 0x0020)
    tc.write_string(cmd_file, S, 0x0040)
    tc.write_string(cmd_file, A, 0x0060)
    tc.write_string(cmd_file, M1, 0x0080)
    tc.write_string(cmd_file, M2, 0x00A0)
    ctx = tc.run_op(cmd_file, "eddsa_verify", 0x0, 0x1, 160, ops_cfg, test_dir, run_name=run_name)

    res = tc.read_output(test_dir, run_name, 0x1000, 1)

    if res != 0:
        tc.print_failed()
        ret = 1
    else:
        tc.print_passed()

    #######################################################################################
    # Invalid A
    #######################################################################################

    run_name = f"{test_name}_invA"
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    R = "2ef9ff1d7926588de9c68104492034a8a8edab57686d95729de313fc70a8623a"
    S = "86031e5bffd2b8fa2b5daf20a09dae43994d209d24042a34ba17cc6cea8ce40f"
    A = "f13c21fd271db83863eab2d4d9a9b503fe745dcb15da3ef5a607a27f7478bbd0"
    M1 = "8f13b3a29344b73d22e681e9faeb3fedb88c94f7504f8f2ac2f17a09fc33a1f6"
    M2 = "b83275219d83def87aa1f74537c8819db6759c80fff5b4c42aa09b663c5304d9"

    tc.start(cmd_file)
    tc.write_string(cmd_file, R, 0x0020)
    tc.write_string(cmd_file, S, 0x0040)
    tc.write_string(cmd_file, A, 0x0060)
    tc.write_string(cmd_file, M1, 0x0080)
    tc.write_string(cmd_file, M2, 0x00A0)
    ctx = tc.run_op(cmd_file, "eddsa_verify", 0x0, 0x1, 160, ops_cfg, test_dir, run_name=run_name)

    res = tc.read_output(test_dir, run_name, 0x1000, 1)

    if res != 0:
        tc.print_failed()
        ret = 1
    else:
        tc.print_passed()

    #######################################################################################
    # Invalid M
    #######################################################################################

    run_name = f"{test_name}_invM"
    tc.print_run_name(run_name)

    cmd_file = tc.get_cmd_file(test_dir)

    R = "2ef9ff1d7926588de9c68104492034a8a8edab57686d95729de313fc70a8623a"
    S = "86031e5bffd2b8fa2b5daf20a09dae43994d209d24042a34ba17cc6cea8ce40f"
    A = "f13c21fd271db83863eab2d4d9a9b503fe745dcb15da3ef5a607a27f7478bbd1"
    M1 = "8f13b3a29344b73d22e681e9faeb3fedb88c94f7504f8f2ac2f17a09fc33a1f6"
    M2 = "b83275219d83def87aa0f74537c8819db6759c80fff5b4c42aa09b663c5304d9"

    tc.start(cmd_file)
    tc.write_string(cmd_file, R, 0x0020)
    tc.write_string(cmd_file, S, 0x0040)
    tc.write_string(cmd_file, A, 0x0060)
    tc.write_string(cmd_file, M1, 0x0080)
    tc.write_string(cmd_file, M2, 0x00A0)
    ctx = tc.run_op(cmd_file, "eddsa_verify", 0x0, 0x1, 160, ops_cfg, test_dir, run_name=run_name)

    res = tc.read_output(test_dir, run_name, 0x1000, 1)

    if res != 0:
        tc.print_failed()
        ret = 1
    else:
        tc.print_passed()

    sys.exit(ret)
