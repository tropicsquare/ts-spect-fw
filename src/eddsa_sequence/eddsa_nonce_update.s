; ==============================================================================
;  file    src/eddsa_sequence/eddsa_nonce_update.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Updates EdDSA nonce derivation with next 144B chunk of the message.
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
;   E = SHA512(R, A, M) ---------> r25
;
; ==============================================================================

op_eddsa_nonce_update:
    ; Check and update OP Link context
    LD          r1,  ca_op_link
    CMPI        r1,  eddsa_nonce_init_id
    BRZ         eddsa_nonce_update_ctx_ok
    CMPI        r1,  eddsa_nonce_update_id
    BRNZ        eddsa_ctx_fail

eddsa_nonce_update_ctx_ok:
    MOVI        r1,  eddsa_nonce_update_id
    ST          r1,  ca_op_link

    CALL        eddsa_nonce_load_msg

    MOVI        r11, 8

eddsa_nonce_update_loop_l1:
    MOVI        r12, 18
eddsa_nonce_update_loop_l2:
    CALL        eddsa_nonce_shift

    SUBI        r12, r12, 1
    BRNZ        eddsa_nonce_update_loop_l2

    TMAC_UP     r1

    SUBI        r11, r11, 1
    BRNZ        eddsa_nonce_update_loop_l1

    MOVI        r0,  ret_op_success
    MOVI        r1,  0
    JMP         set_res_word
