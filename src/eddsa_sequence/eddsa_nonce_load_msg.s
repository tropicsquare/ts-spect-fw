eddsa_nonce_load_msg:
    CALL        get_input_base
    ADDI        r30, r0,  eddsa_input_message
    MOVI        r1,  0
    LDR         r2,  r30
    ADDI        r30, r30, 32
    LDR         r3,  r30
    ADDI        r30, r30, 32
    LDR         r4,  r30
    ADDI        r30, r30, 32
    LDR         r5,  r30
    ADDI        r30, r30, 32
    LDR         r6,  r30

    SWE         r2,  r2
    SWE         r3,  r3
    SWE         r4,  r4
    SWE         r5,  r5
    SWE         r6,  r6
    RET