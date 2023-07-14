op_ecc_key_gen:
    

    MOVI    r0, ret_op_success
    MOVI    r1, 1
    MOVI    r30, ecc_key_gen_id
    JMP     __end__
op_ecc_key_store:

    MOVI    r0, ret_op_success
    MOVI    r1, 1
    MOVI    r30, ecc_key_store_id
    JMP     __end__
op_ecc_key_read:

    MOVI    r0, ret_op_success
    MOVI    r1, 32
    MOVI    r30, ecc_key_read_id
    JMP     __end__
op_ecc_key_erase:

    MOVI    r0, ret_op_success
    MOVI    r1, 1
    MOVI    r30, ecc_key_erase_id
    JMP     __end__