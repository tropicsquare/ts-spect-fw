; ==============================================================================
;  file    ops/ecdsa_ops.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
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
    ORI     r25, r25, 1                 ; pub key slot

    ; Read public key slot
    LDK     r5,  r25, ecc_key_metadata
    BRE     ecdsa_sign_kbus_err_fail
    MOVI    r6,  0xFF
    AND     r5,  r5,  r6
    CMPI    r5,  ecc_type_p256
    BRNZ    ecdsa_sign_curve_type_fail

    LDK     r5,  r25, ecc_pub_key_Ax
    BRE     ecdsa_sign_kbus_err_fail
    ST      r5,  ca_ecdsa_sign_internal_Ax
    LDK     r5,  r25, ecc_pub_key_Ay
    BRE     ecdsa_sign_kbus_err_fail
    ST      r5,  ca_ecdsa_sign_internal_Ay
    KBO     r25, ecc_kbus_flush

    ; Change slot to priv key
    SUBI    r25, r25, 1

    ; Read private key slot
    LDK     r26, r25, ecc_priv_key_1     ; Load privkey part d1
    BRE     ecdsa_sign_kbus_err_fail
    LDK     r22, r25, ecc_priv_key_2     ; Load privkey part w
    BRE     ecdsa_sign_kbus_err_fail
    LDK     r21, r25, ecc_priv_key_3     ; Load privkey part d2
    BRE     ecdsa_sign_kbus_err_fail
    LDK     r23, r25, ecc_priv_key_4     ; Load privkey part w mask
    BRE     ecdsa_sign_kbus_err_fail
    KBO     r25, ecc_kbus_flush

    ; Load message
    ADDI    r4,  r0,  ecdsa_input_message
    LDR     r18, r4
    SWE     r18, r18

    ; Rerandomize d part
    LD      r31, ca_q256
    GRV     r2
    LD      r1, ca_gfp_gen_dst
    CALL    hash_to_field
    SUBP    r26, r26, r0
    ADDP    r21, r21, r0

    ; Rerandomize w part
    GRV     r10
    XOR     r22, r22, r10
    XOR     r23, r23, r10

.ifdef ECC_KEY_RERANDOMIZE
    ; Store the rerandomized priv keys back to flash slot
    KBO         r25, ecc_kbus_erase             ; Erase the slot before writing remasked keys
    BRE         eddsa_set_context_kbus_fail
    STK         r21, r25, ecc_priv_key_1        ; store d1
    BRE         ed25519_key_setup_kbus_fail
    STK         r22, r25, ecc_priv_key_2        ; store w
    BRE         ed25519_key_setup_kbus_fail
    STK         r26, r25, ecc_priv_key_3        ; store d2
    BRE         ed25519_key_setup_kbus_fail
    STK         r23, r25, ecc_priv_key_4        ; w mask
    BRE         ed25519_key_setup_kbus_fail
    KBO         r25, ecc_kbus_program           ; program
    BRE         ed25519_key_setup_kbus_fail
    KBO         r25, ecc_kbus_flush             ; flush
    BRE         ed25519_key_setup_kbus_fail
.endif

    ; unmask w
    XOR         r20, r22, r23

    ; Load secure channel hasn/nonce
    LD      r16, ecdsa_sign_input_sch
    SWE     r16, r16
    LD      r17, ecdsa_sign_input_scn

    JMP     ecdsa_sign

ecdsa_sign_curve_type_fail:
    KBO     r25, ecc_kbus_flush
    MOVI    r3,  ret_curve_type_err
    JMP     ecdsa_sign_invalid_key_fail
ecdsa_sign_kbus_err_fail:
    KBO     r25, ecc_kbus_flush
    MOVI    r3,  ret_key_err
ecdsa_sign_invalid_key_fail:
    KBO     r25, ecc_kbus_flush
    CALL    get_output_base
    ADDI    r30, r0,  ecdsa_output_result
    MOVI    r2,  l3_result_invalid_key
    STR     r2,  r30
    MOV     r0,  r3
    MOVI    r1,  1
    JMP     set_res_word
