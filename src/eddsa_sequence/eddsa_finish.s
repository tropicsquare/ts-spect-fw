op_eddsa_finish:
    LD          r31, ca_q25519
    ; Compute S = r * e*s1 + e*s2
    GRV         r1
    SUBP        r2,  r26, r1

    MULP        r1,  r1,  r16
    MULP        r2,  r2,  r16
    ADDP        r3,  r27, r1
    ADDP        r3,  r0,  r2

    ST          r3,  ca_eddsa_sign_internal_S

    ; decompres public key to extended coordinates
    LD          r31, ca_p25519
    LD          r6,  ca_ed25519_d
    LD          r12, ca_eddsa_sign_internal_A
    CALL        point_decompress_ed25519

    XORI        r30, r1,  0
    BRNZ        eddsa_finish_fail
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    ; Compute e.A
    MOV         r28, r16

    CALL        spm_ed25519_short

    ST          r7,  ca_eddsa_sign_internal_EAx
    ST          r8,  ca_eddsa_sign_internal_EAy
    ST          r9,  ca_eddsa_sign_internal_EAz
    ST          r10, ca_eddsa_sign_internal_EAt

    ; Compute S.G
    LD          r28, ca_eddsa_sign_internal_S
    LD          r11, ca_ed25519_xG
    LD          r12, ca_ed25519_yG
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    CALL        spm_ed25519_short

    LD          r11, ca_eddsa_sign_internal_EAx
    LD          r12, ca_eddsa_sign_internal_EAy
    LD          r13, ca_eddsa_sign_internal_EAz
    LD          r14, ca_eddsa_sign_internal_EAt

    MOVI        r0,  0
    SUBP        r11, r11, r0
    SUBP        r14, r14, r0

    CALL        point_add_ed25519
    MOV         r7,  r11
    MOV         r8,  r12
    MOV         r9,  r13

    ; ENC(Q)
    CALL        point_compress_ed25519

    LD          r4,  ca_eddsa_sign_internal_R

    CALL        get_output_base
    ADDI        r30, r0,  eddsa_output_result

    XOR         r2,  r8,  r4
    BRNZ        eddsa_finish_fail

    MOVI        r2,  l3_result_ok
    STR         r2,  r30
    ADDI        r30, r0,  eddsa_finish_output_R
    STR         r4,  r30
    ADDI        r30, r0,  eddsa_finish_output_S
    LD          r4,  ca_eddsa_sign_internal_S
    STR         r4,  r30

    MOVI        r0,  ret_op_success
    MOVI        r1,  48
    JMP         set_res_word

eddsa_finish_fail:
    MOVI        r2,  l3_result_fail
    STR         r2,  r30

    MOVI        r0,  ret_eddsa_err_final_verify
    MOVI        r1,  1
    JMP         set_res_word
