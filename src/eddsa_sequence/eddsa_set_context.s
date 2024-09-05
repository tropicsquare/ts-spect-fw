; ==============================================================================
;  file    eddsa_sequence/eddsa_set_context.s
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
; Sets context for EdDSA sequence
;
; Loads keys from slot, loads Secure Chanel Hash and Nonce.
;
;   Public key A ----------------> ca_eddsa_sign_internal_A
;   Private key part 's1' --------> ca_eddsa_sign_internal_s1
;   Private key part 's2' --------> ca_eddsa_sign_internal_s2
;   Private key part 'prefix' ---> r20
;   Secure Channel Hash ---------> r16
;   Secure Channel Nonce --------> r17
;
;   Rerandomize private keys and store them back to flash slot
;
; ==============================================================================
;
; Overall EdDSA sequence context
;   Public key 'A' --------------> ca_eddsa_sign_internal_A
;   Private key part 's' --------> r26
;   Private key part 'prefix' ---> r20
;   Secure Channel Hash ---------> r16
;   Secure Channel Nonce --------> r17
;   Nonce 'r' -------------------> r27
;   Signature part 'R' ----------> ca_eddsa_sign_internal_R
;   SHA512(R, A, M) -------------> r25
;
; ==============================================================================

op_eddsa_set_context:
    CALL    get_input_base
    ADDI    r4,  r0,  eddsa_set_context_input_slot
    LDR     r1,  r4
    ROR8    r1,  r1

    LSL     r22, r1                             ; priv key slot
    ADDI    r21, r22, 1                         ; pub key slot

    MOVI    r1,  0

    LDK     r16, r21, ecc_key_metadata          ; load slot metadata
    BRE     eddsa_set_context_kbus_fail
    MOVI    r0,  0xFF
    AND     r16, r16, r0
    CMPI    r16, ecc_type_ed25519               ; check curve type
    BRNZ    eddsa_set_context_curve_type_fail

    ; load public key
    LDK     r25, r21, ecc_pub_key_Ax
    BRE     eddsa_set_context_kbus_fail
    ST      r25, ca_eddsa_sign_internal_A
    KBO     r21, ecc_kbus_flush
    BRE     eddsa_set_context_kbus_fail

    MOV     r21, r22

    ; load private keys
    LDK     r26, r21, ecc_priv_key_1
    BRE     eddsa_set_context_kbus_fail
    LDK     r23, r21, ecc_priv_key_2
    BRE     eddsa_set_context_kbus_fail
    LDK     r29, r21, ecc_priv_key_3
    BRE     eddsa_set_context_kbus_fail
    LDK     r30, r21, ecc_priv_key_4
    BRE     eddsa_set_context_kbus_fail
    KBO     r21, ecc_kbus_flush
    BRE     eddsa_set_context_kbus_fail

    ; Rerandomize
    LD          r31, ca_q25519
    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field
    SUBP        r26, r26, r0
    ADDP        r29, r29, r0

    GRV         r2
    XOR         r23, r23, r2
    XOR         r30, r30, r2

.ifdef ECC_KEY_RERANDOMIZE
    ; Store back to ECC priv key slot
    KBO         r21, ecc_kbus_erase             ; Erase the slot before writing remasked keys
    BRE         eddsa_set_context_kbus_fail
    STK         r26, r21, ecc_priv_key_1        ; store s1
    BRE         ed25519_key_setup_kbus_fail
    STK         r23, r21, ecc_priv_key_2        ; store prefix
    BRE         ed25519_key_setup_kbus_fail
    STK         r29, r21, ecc_priv_key_3        ; store s2
    BRE         ed25519_key_setup_kbus_fail
    STK         r30, r21, ecc_priv_key_4        ; prefix mask
    BRE         ed25519_key_setup_kbus_fail
    KBO         r21, ecc_kbus_program           ; program
    BRE         ed25519_key_setup_kbus_fail
    KBO         r21, ecc_kbus_flush             ; flush
    BRE         ed25519_key_setup_kbus_fail
.endif

    ; unmask prefix and store the masked s for later use
    XOR     r20, r23, r30
    ST      r26, ca_eddsa_sign_internal_s1
    ST      r29, ca_eddsa_sign_internal_s2

    ; load secure channel nonce + hash
    LD      r16, eddsa_set_context_input_sch
    SWE     r16, r16
    LD      r17, eddsa_set_context_input_scn

    MOVI    r0,  ret_op_success
    MOVI    r1,  0
    JMP     set_res_word


eddsa_ret_invalid_key:
    KBO     r21, ecc_kbus_flush
    CALL    get_output_base
    ADDI    r30, r0,  eddsa_output_result
    MOVI    r2,  l3_result_invalid_key
    STR     r2,  r30
    MOVI    r1,  1
    RET

eddsa_set_context_kbus_fail:
    CALL    eddsa_ret_invalid_key
    MOVI    r0,  ret_key_err
    JMP     set_res_word

eddsa_set_context_curve_type_fail:
    CALL    eddsa_ret_invalid_key
    MOVI    r0,  ret_curve_type_err
    JMP     set_res_word
