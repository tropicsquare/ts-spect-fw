op_x25519_kpair_gen:
    MOVI    r0, ret_op_success
    MOVI    r1, 32
    MOVI    r30, x25519_kpair_gen_id
    JMP     set_res_word
    
op_x25519_sc_et_eh:
    MOVI    r0, ret_op_success
    MOVI    r1, 32
    MOVI    r30, x25519_sc_et_eh_id
    JMP     set_res_word
    
op_x25519_sc_et_sh:
    MOVI    r0, ret_op_success
    MOVI    r1, 32
    MOVI    r30, x25519_sc_et_sh_id
    JMP     set_res_word
    
op_x25519_sc_st_eh:
    MOVI    r0, ret_op_success
    MOVI    r1, 32
    MOVI    r30, x25519_sc_st_eh_id
    JMP     set_res_word
    