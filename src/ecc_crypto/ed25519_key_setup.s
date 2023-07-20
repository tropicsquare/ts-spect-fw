; Key setup for curve Ed25519 (EdDSA)
;
; Inputs:
;   seed k in r19
;   slot to write the key to in r25
;
; Outputs:
;   Writes the key trio (s, prefix, A) to ECC key slot via KBUS
;   spect status in r3
;
; Expects:
;   --
;

ed25519_key_setup:
    ; Add padding to k
    MOVI        r18, 1
    ROR         r18, r18
    MOVI        r17, 0
    MOVI        r16, 256
    ; H = SHA512(k)
    HASH_IT
    HASH        r28, r16
    ; Mask H[255:0] to become scalar s
    MOVI        r0,  7
    MOVI        r1,  255
    SBIT        r0,  r0, r1
    NOT         r0,  r0
    AND         r28, r0, r28
    MOVI        r1,  254
    SBIT        r28, r28, r1

    ST          r28, ca_ed25519_key_setup_internal_s
    ST          r29, ca_ed25519_key_setup_internal_prefix

    ; Load base point G and check its validity
    LD          r31, ca_p25519
    LD          r11, ca_eddsa_xG
    LD          r12, ca_eddsa_yG
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    LD          r6,  ca_eddsa_d

    MOV         r7,  r11
    MOV         r8,  r12
    MOV         r9,  r13

    CALL        point_check_ed25519
    BRNZ        ed25519_key_setup_spm_fail
    ; Calculate A = s.G and check validity of the result
    CALL        spm_ed25519_short
    CALL        point_check_ed25519
    BRNZ        ed25519_key_setup_spm_fail
    ; Transform A back to affine coordinates
    CALL        point_compress_ed25519
    ; Get private key slot
    LSL         r25, r25
    ; Get pubkey slot
    ADDI        r26, r25, 1
    ; Compose kpair metadata (origin, curve)
    LD          r0,  ca_spect_cfg_word
    MOVI        r4,  0xFF
    AND         r9,  r0,  r4        ; mask SPECT_OP_ID to r1[7:0]
    ROL8        r9,  r9
    ORI         r9,  r9,  ecc_type_ed25519
    STK         r9,  r26, 0x400     ; store metadata
    BRE         ed25519_key_setup_kbus_fail
    ; Store the pubkey to key slot
    STK         r8,  r26, 0x400     ; store A
    BRE         ed25519_key_setup_kbus_fail
    
    KBO         r26, 0x402          ; program
    BRE         ed25519_key_setup_kbus_fail
    KBO         r26, 0x405          ; flush
    BRE         ed25519_key_setup_kbus_fail

    ; Store s and prefix to key slot
    LD          r28, ca_ed25519_key_setup_internal_s
    LD          r29, ca_ed25519_key_setup_internal_prefix

    STK         r28, r25, 0x400     ; store s
    BRE         ed25519_key_setup_kbus_fail
    STK         r29, r25, 0x401     ; store prefix
    BRE         ed25519_key_setup_kbus_fail
    KBO         r25, 0x402          ; program
    BRE         ed25519_key_setup_kbus_fail
    KBO         r25, 0x405          ; flush
    BRE         ed25519_key_setup_kbus_fail
    ; Return success
    MOVI        r3,  0
    RET

ed25519_key_setup_spm_fail:
    MOVI        r3, ret_spm_err
    RET

ed25519_key_setup_kbus_fail:
    MOVI        r3, ret_key_err
    RET