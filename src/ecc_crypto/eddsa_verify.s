;
; Inputs:
;   R part  : 0x0020-0x003F
;   S part  : 0x0040-0x005F
;   Pub key : 0x0060-0x007F
;   Pub key : 0x0080-0x00BF
;
; Outputs:
;   Fail/Success : 0x

eddsa_verify:
    ; load and set needed parameters
    LD          r28, eddsa_verify_input_S
    LD          r31, ca_p25519
    LD          r6,  ca_eddsa_d
    LD          r11, ca_eddsa_xG
    LD          r12, ca_eddsa_yG
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    ; Q1 = S . B
    CALL        spm_ed25519_short
    ST          r7,  ca_eddsa_verify_internal_SBx
    ST          r8,  ca_eddsa_verify_internal_SBy
    ST          r9,  ca_eddsa_verify_internal_SBz
    ST          r10, ca_eddsa_verify_internal_SBt
bp_eddsa_verify_sxb:

    ; Load Rest of Inputs
    LD          r24, eddsa_verify_input_message1
    LD          r25, eddsa_verify_input_message0
    LD          r26, eddsa_verify_input_pubkey
    LD          r27, eddsa_verify_input_R

    SWE         r20, r24
    SWE         r21, r25
    SWE         r22, r26
    SWE         r23, r27

    ; E = SHA512(ENC(R)||ENC(A)||M) mod q
    HASH_IT
    HASH        r28, r20

    MOVI        r3,  0x80
    ROR8        r3,  r3
    MOVI        r2,  0
    MOVI        r1,  0
    MOVI        r0,  1024

    HASH        r28, r0

    SWE         r28, r28
    SWE         r29, R29
bp_eddsa_verify_after_hram:
    LD          r31, ca_q25519
    REDP        r28, r28, r29

    ; Decompress ENC(A)
    LD          r31, ca_p25519
    MOV         r12, r26
    CALL        point_decompress_ed25519
bp_eddsa_verify_deca:
.ifdef SPECT_ISA_VERSION_1
    CMPA        r1,  0
.endif
.ifdef SPECT_ISA_VERSION_2
    MOVI        r30, 0
    XOR         r1, r1, r30
.endif
    BRNZ        eddsa_verify_fail
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    ; Q2 = E . A
    CALL        spm_ed25519_short

bp_eddsa_verify_exa:
    ; Q = Q1 - Q2
    MOVI        r0,  0
    SUBP        r7,  r0,  r7
    SUBP        r10, r0,  r10

    LD          r11, ca_eddsa_verify_internal_SBx
    LD          r12, ca_eddsa_verify_internal_SBy
    LD          r13, ca_eddsa_verify_internal_SBz
    LD          r14, ca_eddsa_verify_internal_SBt

    CALL        point_add_ed25519
    MOV         r7,  r11
    MOV         r8,  r12
    MOV         r9,  r13

    ; ENC(Q)
    CALL        point_compress_ed25519

    MOVI        r0,  ret_op_success
    MOVI        r1,  1
bp_eddsa_verify_encq:
    ; ENC(Q) == ENC(R)
.ifdef SPECT_ISA_VERSION_1
    LD          r31, ca_ffff
    SUBP        r2,  r23, r8
    CMPA        r2,  0
.endif
.ifdef SPECT_ISA_VERSION_2
    XOR         r2,  r23, r8
.endif
    BRZ         eddsa_verify_success
eddsa_verify_fail:
    MOVI        r2,  0
    ST          r2,  eddsa_verify_output_result
    JMP         set_res_word

eddsa_verify_success:
    MOVI        r2,  1
    ST          r2,  eddsa_verify_output_result
    JMP         set_res_word
