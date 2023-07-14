op_ecdsa_sign:
    MOVI    r0, ret_op_success
    MOVI    r1, 80
    MOVI    r30, ecdsa_sign_id
    JMP     set_res_word