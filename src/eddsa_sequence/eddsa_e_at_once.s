op_eddsa_e_at_once:
    ; Load all data
    CALL        get_data_in_size
    MOV         r11, r0             ; number of bytes in message

    CALL        get_input_base
    ADDI        r30, r0,  eddsa_input_message
    LDR         r19, r30
    ADDI        r30, r30, 32
    LDR         r18, r30

    SWE         r19, r19
    SWE         r18, r18

    LD          r20, ca_eddsa_sign_internal_A
    LD          r21, ca_eddsa_sign_internal_R

    ; make mask for sign
    MOVI        r15, 0x80
    ROL8        r15, r15
    ROL8        r15, r15
    ROL8        r15, r15

    ; get size of message in bites
    LSL         r12, r11
    LSL         r12, r12
    LSL         r12, r12            ; bitsize of message

    ; init hash unit
    HASH_IT

    ; prepare for LSB bits maski
    MOVI        r6, 0
    NOT         r5, r6

    ; check in which register the padding shall start
    SUBI        r10, r11, 32
    AND         r9,  r10, r15
    BRZ         eddsa_e_at_once_pad_reg_2
eddsa_e_at_once_pad_reg_1:
eddsa_e_at_once_pad_reg_1_mask_loop:
    ROLIN       r5, r5, r6
    ADDI        r10, r10, 1
    BRNZ        eddsa_e_at_once_pad_reg_1_mask_loop

    AND         r19, r19, r5
    MOVI        r10, 255
    SUB         r10, r10, r12
    SBIT        r19, r19, r10

eddsa_e_at_once_pad_reg_2:
    SUBI        r10, r10, 32
eddsa_e_at_once_pad_reg_2_mask_loop:
    ROLIN       r5, r5, r6
    ADDI        r10, r10, 1
    BRNZ        eddsa_e_at_once_pad_reg_2_mask_loop

    AND         r18, r18, r5
    MOVI        r10, 511
    SUB         r10, r10, r12
    SBIT        r18, r18, r10

eddsa_e_at_once_msg_size:

    SUBI        r10, r11, 48
    AND         r9,  r10, r15
    BRZ         eddsa_e_at_once_next_block

    OR          r18, r18, r12
    HASH        r16, r18

    JMP         eddsa_e_at_once_reduce

eddsa_e_at_once_next_block:
    HASH        r16, r18

    MOVI        r13, 0
    MOVI        r14, 0
    MOVI        r15, 0

    HASH        r16, r12

eddsa_e_at_once_reduce:
    LD          r31, ca_q25519
    REDP        r16, r17, r16

    MOVI        r0, ret_op_success
    MOVI        r1,  0
    JMP         set_res_word
