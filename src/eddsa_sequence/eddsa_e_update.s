op_eddsa_e_update:
    CALL        eddsa_e_load_message

    HASH        r16, r18

    ADDI        r29, r29, 128     ; update byte counter of messsage size

    MOVI        r0, ret_op_success
    MOVI        r1,  0
    JMP         set_res_word
