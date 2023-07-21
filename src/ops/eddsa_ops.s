op_eddsa_set_context:
    MOVI    r0, ret_op_success
    MOVI    r1, 0
    MOVI    r30, eddsa_set_context_id
    JMP     set_res_word

op_eddsa_nonce_init:
    MOVI    r0, ret_op_success
    MOVI    r1, 0
    MOVI    r30, eddsa_nonce_init_id
    JMP     set_res_word

op_eddsa_nonce_update:
    MOVI    r0, ret_op_success
    MOVI    r1, 0
    MOVI    r30, eddsa_nonce_update_id
    JMP     set_res_word

op_eddsa_nonce_finish:
    MOVI    r0, ret_op_success
    MOVI    r1, 0
    MOVI    r30, eddsa_nonce_finish_id
    JMP     set_res_word

op_eddsa_R_part:
    MOVI    r0, ret_op_success
    MOVI    r1, 0
    MOVI    r30, eddsa_R_part_id
    JMP     set_res_word

op_eddsa_e_at_once:
    MOVI    r0, ret_op_success
    MOVI    r1, 0
    MOVI    r30, eddsa_e_at_once_id
    JMP     set_res_word

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

op_eddsa_finish:
    MOVI    r0, ret_op_success
    MOVI    r1, 80
    MOVI    r30, eddsa_finish_id
    JMP     set_res_word

op_eddsa_verify:
    JMP     eddsa_verify
    JMP     set_res_word
