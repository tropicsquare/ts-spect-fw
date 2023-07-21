; ECDSA P-256 Key Setup
;
; Input:
;   seed k in r19
;   slot to write the key to in r25
;
; Outputs:
;   Writes the key trio (d, w, A) to ECC key slot via KBUS
;   spect status in r3

p256_key_setup:
    LD r31, ca_q256

    MOVI    r1,  0
    REDP    r28, r1,  r19

.ifdef SPECT_ISA_VERSION_1
    CMPA    r28, 0
.endif

.ifdef SPECT_ISA_VERSION_2
    XORI    r1,  r28, 0
.endif

    BRZ p256_key_setup_fail

.ifdef SPECT_ISA_VERSION_1
    MOVI    r17, 0
.endif

.ifdef SPECT_ISA_VERSION_2
    TMAC_IT r0
    TMAC_IS r16, 0xA

    MOVI    r2,  0x04
    MOVI    r30, 17
p256_key_setup_tmac_padding_loop:
    ROL8    r2,  r2
    SUBI    r30, r30, 1
    BRNZ    p256_key_setup_tmac_padding_loop

    TMAC_UP r2
    TMAC_RD r29
.endif

    ST      r28, ca_p256_key_setup_internal_d
    ST      r29, ca_p256_key_setup_internal_w

    LD      r31, ca_p256

    LD      r12, ca_p256_xG
    LD      r13, ca_p256_yG
    MOVI    r14, 1

    MOV     r9,  r12
    MOV     r10, r13
    MOV     r11, r14

    CALL    point_check_p256
    BRNZ    p256_key_setup_spm_fail

    LD      r8,  ca_p256_b

    CALL    spm_p256_short
    CALL    point_check_p256
    BRNZ    p256_key_setup_spm_fail

    MOV     r1, r11
    CALL    inv_p256
    MUL256  r9, r9, r1
    MUL256  r10, r10, r1

    ; Get private key slot
    LSL         r25, r25
    ; Get pubkey slot
    ADDI        r26, r25, 1
    ; Compose kpair metadata (origin, curve)
    LD          r0,  ca_spect_cfg_word
    MOVI        r4,  0xFF
    AND         r20, r0,  r4        ; mask SPECT_OP_ID to r1[7:0]
    ROL8        r20, r20
    ORI         r20, r20, ecc_type_p256
    STK         r20, r26, 0x400     ; store metadata
    BRE         p256_key_setup_fail
    ; Store the pubkey to key slot
    STK         r9,  r26, 0x400     ; store Ax
    BRE         p256_key_setup_fail
    STK         r10, r26, 0x400     ; store Ay
    BRE         p256_key_setup_fail
    
    KBO         r26, 0x402          ; program
    BRE         p256_key_setup_fail
    KBO         r26, 0x405          ; flush
    BRE         p256_key_setup_fail

    ; Store s and prefix to key slot
    LD          r28, ca_p256_key_setup_internal_d
    LD          r29, ca_p256_key_setup_internal_w

    STK         r28, r25, 0x400     ; store d
    BRE         p256_key_setup_fail
    STK         r29, r25, 0x401     ; store w
    BRE         p256_key_setup_fail
    KBO         r25, 0x402          ; program
    BRE         p256_key_setup_fail
    KBO         r25, 0x405          ; flush
    BRE         p256_key_setup_fail

    MOVI    r3, ret_op_success

    RET
    
p256_key_setup_fail:
    MOVI    r3,  ret_key_err
    RET
p256_key_setup_spm_fail:
    MOVI    r3,  ret_spm_err
    RET