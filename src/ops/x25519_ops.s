op_x25519_kpair_gen:
    GRV     r19
    MOVI    r0,  7
    SBIT    r0,  255
    NOT     r0,  r0
    AND     r19, r0, r19
    SBIT    r19, 254

    ST      r19, x25519_context_etpriv

    MOVI    r16, 9
    MOVI    r0,  0xD3

    CALL    x25519_full_masked

    ST      r11, x25519_kpair_gen_output_etpub

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
    