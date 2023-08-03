op_eddsa_e_prep:
    MOVI    r0, ret_op_success
    MOVI    r1, 0
    MOVI    r30, eddsa_e_prep_id
    JMP     set_res_word

op_eddsa_e_update:
    MOVI    r0, ret_op_success
    MOVI    r1, 0
    MOVI    r30, eddsa_e_update_id
    JMP     set_res_word

op_eddsa_e_finish:
    MOVI    r0, ret_op_success
    MOVI    r1, 0
    MOVI    r30, eddsa_e_finish_id
    JMP     set_res_word

op_eddsa_verify:
    JMP     eddsa_verify
    JMP     set_res_word
