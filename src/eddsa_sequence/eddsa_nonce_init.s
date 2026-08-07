; ==============================================================================
;  file    eddsa_sequence/eddsa_nonce_init.s
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
; Initialize TMAC for deterministic nonce derivation with init string and SCH SCN
;
; Expected context:
;   Private key part 'prefix' <--- r20
;   Secure Channel Hash <--------- r16
;   Secure Channel Nonce <-------- r17
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

op_eddsa_nonce_init:
    ; Check and update OP Link context
    LD          r1,  ca_op_link
    CMPI        r1,  eddsa_set_context_id
    BRNZ        eddsa_ctx_fail
    MOVI        r1,  eddsa_nonce_init_id
    ST          r1,  ca_op_link

    GRV         r7
    CALL        extend_tmac_mask
    TMAC_IT     r7

    TMAC_IS     r20, tmac_dst_eddsa_sign

    CALL        tmac_sch_scn

    MOVI        r1,  0
    MOVI        r0,  ret_op_success
    JMP         set_res_word
