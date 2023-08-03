#!/usr/bin/env python3
import sys
import binascii
import hashlib
import random as rn
import os

import test_common as tc
import models.ed25519 as ed25519

def sha512(s):
    return hashlib.sha512(s).digest()

def boot_sequence(signature, A, message, name, isa):
    main="src/boot_main.s"

    message_padded = message + b'\x80'
    while len(message_padded) % 128 != (128 - 16):
        message_padded += b'\x00'

    message_padded += int.to_bytes(len(message)*8, 16, 'big')

    m_blocks = []
    for i in range(0, len(message_padded), 128):
        m_blocks.append(message_padded[i:i+128])

    cmd_file = tc.get_cmd_file(test_dir)
    tc.print_run_name("sha512_init")
    tc.start(cmd_file)
    ctx = tc.run_op(cmd_file, "sha512_init", 0x0, 0x1, 0, ops_cfg, test_dir, main=main, isa=isa)

    for i in range(len(m_blocks)-1):
        tc.print_run_name(f"sha512_update_{i}")
        cmd_file = tc.get_cmd_file(test_dir)
        tc.start(cmd_file)
        tc.write_bytes(cmd_file, m_blocks[i], 0x0010)
        run_name = "sha512_update" + f"_{i}"
        ctx = tc.run_op(cmd_file, "sha512_update", 0x0, 0x1, 128, ops_cfg, test_dir, run_name=run_name, old_context=ctx, main=main, isa=isa)

    tc.print_run_name("sha512_final")
    cmd_file = tc.get_cmd_file(test_dir)
    tc.start(cmd_file)
    tc.write_bytes(cmd_file, m_blocks[-1], 0x0010)
    ctx = tc.run_op(cmd_file, "sha512_final", 0x0, 0x1, 128, ops_cfg, test_dir, old_context=ctx, main=main, isa=isa)

    digest_int = tc.read_output(test_dir, "sha512_final", 0x1010, 16)
    digest = int.to_bytes(digest_int, 64, 'little')

    run_name=f"eddsa_verify_{name}"
    tc.print_run_name(run_name)
    cmd_file = tc.get_cmd_file(test_dir)

    tc.start(cmd_file)
    tc.write_bytes(cmd_file, signature, 0x0020)
    tc.write_bytes(cmd_file, A, 0x0060)
    tc.write_bytes(cmd_file, digest, 0x0080)

    ctx = tc.run_op(cmd_file, "eddsa_verify", 0x0, 0x1, 160, ops_cfg, test_dir, run_name=run_name, main=main, isa=isa)

    res = tc.read_output(test_dir, run_name, 0x1000, 1)

    return res == 1

if __name__ == "__main__":    
    ret = 0

    seed = rn.randint(0, 2**32-1)
    rn.seed(seed)
    print("seed:", seed)

    ops_cfg = tc.get_ops_config()
    test_name = "boot_sequence"

    test_dir = tc.make_test_dir(test_name)

    msg_bitlen = rn.randint(2*128, 5*128)*8
    message = int.to_bytes(rn.getrandbits(msg_bitlen), msg_bitlen//8, 'big')

    secret = int.to_bytes(rn.randint(0, 2**256-1), 32, 'little')

    digest_ref = sha512(message)

    signature, A = ed25519.sign(secret, digest_ref)

    #print("Digest ref:", digest_ref.hex())
    #print("A:         ", A.hex())
    #print("signature: ", signature.hex())

    ########################################################################################################
    #   Uncorrupted ISA v0.1
    ########################################################################################################

    if boot_sequence(signature, A, message, "valid_isa_1", isa=1):
        tc.print_passed()
    else:
        tc.print_failed()
        ret = 1

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")
        
    ########################################################################################################
    #   Corrupted message ISA v0.1
    ########################################################################################################

    corrupted_message = message + b'\xAA'

    if not boot_sequence(signature, A, corrupted_message, "corrupted_isa_1", isa=1):
        tc.print_passed()
    else:
        tc.print_failed()
        ret = 1

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

    ########################################################################################################
    #   Uncorrupted ISA v0.2
    ########################################################################################################

    if boot_sequence(signature, A, message, "valid_isa_2", isa=2):
        tc.print_passed()
    else:
        tc.print_failed()
        ret = 1

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

    ########################################################################################################
    #   Corrupted message ISA v0.2
    ########################################################################################################

    corrupted_message = message + b'\xAA'

    if not boot_sequence(signature, A, corrupted_message, "corrupted_isa_2", isa=2):
        tc.print_passed()
    else:
        tc.print_failed()
        ret = 1

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm {test_dir}/*")

    if "TS_SPECT_FW_TEST_DONT_DUMP" in os.environ.keys():
        os.system(f"rm -r {test_dir}")

    sys.exit(ret)