op_eddsa_nonce_update:
    CALL        eddsa_nonce_load_msg

    MOVI        r11, 8

eddsa_nonce_update_loop_l1:
    MOVI        r12, 18
eddsa_nonce_ipdate_loop_l2:
    CALL        eddsa_nonce_shift

    SUBI        r12, r12, 1
    BRNZ        eddsa_nonce_ipdate_loop_l2

    TMAC_UP     r1

    SUBI        r11, r11, 1
    BRNZ        eddsa_nonce_ipdate_loop_l1

    MOVI        r0,  ret_op_success
    JMP         set_res_word
