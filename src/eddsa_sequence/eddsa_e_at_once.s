op_eddsa_e_at_once:
    CALL        get_data_in_size
    MOV         r11, r0             ; number of bytes in the last chunk

    CALL        get_input_base
    ADDI        r30, r0,  eddsa_input_message
    LDR         r2,  r30
    ADDI        r30, r30, 32
    LDR         r2,  r30

    MOVI        r15, 0x80
    ROL8        r15, r15
    ROL8        r15, r15
    ROL8        r15, r15

    SUBI        r10, r11, 48
    AND         r9,  r10, r15
    BRNZ        ; staci 1 blok

    
