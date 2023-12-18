; ==============================================================================
;  file    eddsa_sequence/eddsa_e_prep.s
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
; Prepares for e = SHA512(R, A, M) calculation.
; Process R, A and first 64 byte of the massage.
;
; ==============================================================================

op_eddsa_e_prep:
    CALL        get_input_base
    ADDI        r30, r0,  eddsa_input_message
    LDR         r19, r30
    ADDI        r30, r30, 32
    LDR         r18, r30

    SWE         r19, r19
    SWE         r18, r18

    LD          r20, ca_eddsa_sign_internal_A
    LD          r21, ca_eddsa_sign_internal_R

    HASH_IT
    HASH        r16, r18

    MOVI        r29, 128                        ; byte counter for messsage size

    MOVI        r0, ret_op_success
    MOVI        r1,  0
    JMP         set_res_word
