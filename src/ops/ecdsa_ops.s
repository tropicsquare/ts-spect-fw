; ==============================================================================
;  file    ops/ecdsa_ops.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; ECDSA Ops
;   - ECDSA Sign
;
; ==============================================================================

op_ecdsa_sign:
    CALL    get_input_base
    ADDI    r4,  r0,  ecdsa_input_cmd_in
    LDR     r4,  r4
    ROR8    r25, r4
    MOVI    r2,  0xFF
    AND     r25, r25, r2         ; SLOT

    LSL     r25, r25                    ; priv key slot
    ORI     r26, r25, 1                 ; pub key slot

    LDK     r5,  r26, ecc_key_metadata
    BRE     ecdsa_sign_key_fail
    ANDI    r5,  r5,  0xFF
    CMPI    r5,  ecc_type_p256
    BRNZ    ecdsa_sign_curve_type_fail

    LDK     r5,  r26, ecc_pub_key_Ax
    BRE     ecdsa_sign_key_fail
    ST      r5,  ca_ecdsa_sign_internal_Ax
    LDK     r5,  r26, ecc_pub_key_Ay
    BRE     ecdsa_sign_key_fail
    ST      r5,  ca_ecdsa_sign_internal_Ay
    KBO     r26, ecc_kbus_flush

    LDK     r26, r25, ecc_priv_key_1     ; Load privkey part d
    BRE     ecdsa_sign_key_fail
    LDK     r20, r25, ecc_priv_key_2     ; Load privkey part w
    BRE     ecdsa_sign_key_fail
    KBO     r25, ecc_kbus_flush

    ADDI    r4,  r0,  ecdsa_input_message
    LDR     r18, r4
    SWE     r18, r18
    LD      r16, ecdsa_sign_input_sch
    SWE     r16, r16
    LD      r17, ecdsa_sign_input_scn

    JMP     ecdsa_sign

ecdsa_sign_curve_type_fail:
    MOVI    r3,  ret_curve_type_err
    JMP     ecdsa_sign_fail

ecdsa_sign_key_fail:
    MOVI    r3,  ret_key_err
    JMP     ecdsa_sign_fail
