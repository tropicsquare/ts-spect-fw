op_ecdsa_sign:
    CALL    get_input_base
    ADDI    r4,  r0,  ecdsa_input_cmd_in
    LDR     r4,  r4
    ROR8    r25, r4
    MOVI    r2,  0xFF
    AND     r25, r25, r2         ; SLOT

    ADDI    r4,  r0,  ecdsa_input_message
    LDR     r18, r4
    SWE     r18, r18
    LD      r16, ecdsa_sign_input_sch
    SWE     r16, r16
    LD      r17, ecdsa_sign_input_scn

    LSL     r25, r25
    LDK     r26, r25, ecc_priv_key_1     ; Load privkey part d
    LDK     r20, r25, ecc_priv_key_2     ; Load privkey part w
    KBO     r25, ecc_kbus_flush

    JMP     ecdsa_sign
