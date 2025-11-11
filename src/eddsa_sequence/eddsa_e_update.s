; ==============================================================================
;  file    eddsa_sequence/eddsa_e_update.s
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
; Updates e = SHA512(R, A, M) calculation with next 128 bytes of the message.
;
; ==============================================================================

op_eddsa_e_update:
    ; Check and update OP Link context
    LD          r1,  ca_op_link
    CMPI        r1,  eddsa_e_prep_id
    BRZ         eddsa_e_update_ctx_ok
    CMPI        r1,  eddsa_e_update_id
    BRNZ        eddsa_ctx_fail
eddsa_e_update_ctx_ok:
    MOVI        r1,  eddsa_e_update_id
    ST          r1,  ca_op_link

    CALL        eddsa_e_load_message

    HASH        r16, r18

    ADDI        r29, r29, 128

    MOVI        r0, ret_op_success
    MOVI        r1,  0
    JMP         set_res_word
