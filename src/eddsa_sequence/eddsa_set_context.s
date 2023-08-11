; Sets context for EdDSA sequence
;
;   Loads keys from slot, loads Secure ChanelHash and Nonce.
;
;   Public key A ----------------> ca_eddsa_sign_internal_A
;   Private key part 's' --------> r26
;   Private key part 'prefix' ---> r20
;   Secure Channel Hash ---------> r16
;   Secure Channel Nonce --------> r17

; TODO Integrity checks??

; Overall EdDSA sequence context
;   Public key 'A' --------------> ca_eddsa_sign_internal_A
;   Private key part 's' --------> r26
;   Private key part 'prefix' ---> r20
;   Secure Channel Hash ---------> r16
;   Secure Channel Nonce --------> r17
;   Nonce 'r' -------------------> r27
;   Signature part 'R' ----------> ca_eddsa_sign_internal_R
;   SHA512(R || A || M) ---------> r25

op_eddsa_set_context:
    CALL    get_input_base
    ADDI    r4,  r0,  eddsa_set_context_input_slot
    LDR     r1,  r4
    ROR8    r1,  r1

    LSL     r22, r1         ; priv key slot
    ADDI    r21, r22, 1     ; pub key slot

    MOVI    r1,  0

    LDK     r16, r21, ecc_key_metadata
    BRE     eddsa_set_context_kbus_fail
    MOVI    r0,  0xFF
    AND     r16, r16, r0
    CMPI    r16, ecc_type_ed25519
    BRNZ    eddsa_set_context_curve_type_fail

    LDK     r25, r21, ecc_pub_key_Ax
    BRE     eddsa_set_context_kbus_fail
    ST      r25, ca_eddsa_sign_internal_A
    KBO     r21, ecc_kbus_flush
    BRE     eddsa_set_context_kbus_fail

    LDK     r26, r22, ecc_priv_key_1
    BRE     eddsa_set_context_kbus_fail
    LDK     r20, r22, ecc_priv_key_2
    BRE     eddsa_set_context_kbus_fail
    LDK     r30, r22, ecc_priv_key_3
    BRE     eddsa_set_context_kbus_fail
    ST      r30, ca_eddsa_sign_internal_smodq

    LD      r16, eddsa_set_context_input_sch
    SWE     r16, r16
    LD      r17, eddsa_set_context_input_scn

    MOVI    r0,  ret_op_success
    JMP     set_res_word

eddsa_set_context_kbus_fail:
    MOVI    r0,  ret_key_err
    JMP     set_res_word

eddsa_set_context_curve_type_fail:
    MOVI    r0,  ret_curve_type_err
    JMP     set_res_word
