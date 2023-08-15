; ==============================================================================
;  file    eddsa_sequence/eddsa_e_update.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Updates e = SHA512(R, A, M) calculation with next 128 bytes of the message.
;
; ==============================================================================

op_eddsa_e_update:
    CALL        eddsa_e_load_message

    HASH        r16, r18

    ADDI        r29, r29, 128

    MOVI        r0, ret_op_success
    MOVI        r1,  0
    JMP         set_res_word
