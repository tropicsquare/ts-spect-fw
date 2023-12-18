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
;   Private key part 's' --------> r26
;   Private key part 'prefix' ---> r20
;   Secure Channel Hash ---------> r16
;   Secure Channel Nonce --------> r17
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
    LDK     r20, r21, ecc_priv_key_2
    BRE     eddsa_set_context_kbus_fail
    LDK     r30, r21, ecc_priv_key_3
    BRE     eddsa_set_context_kbus_fail
    ST      r30, ca_eddsa_sign_internal_smodq

    ; load secure channel nonce + hash
    LD      r16, eddsa_set_context_input_sch
    SWE     r16, r16
    LD      r17, eddsa_set_context_input_scn

    MOVI    r0,  ret_op_success
    JMP     set_res_word

eddsa_set_context_kbus_fail:
    KBO     r21, ecc_kbus_verify_erase
    MOVI    r0,  ret_key_err
    JMP     set_res_word

eddsa_set_context_curve_type_fail:
    MOVI    r0,  ret_curve_type_err
    JMP     set_res_word
