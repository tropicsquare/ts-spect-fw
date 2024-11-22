; ==============================================================================
;  file    src/eddsa_sequence/eddsa_nonce_update.s
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
; Updates EdDSA nonce derivation with next 144B chunk of the message.
;
; ==============================================================================

op_eddsa_nonce_update:
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
