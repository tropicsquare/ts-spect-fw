op_eddsa_e_finish:
    CALL        get_data_in_size
    MOV         r11, r0             ; number of bytes in the last chunk of message
    ADD         r29, r29, r11
    LSL         r29, r29
    LSL         r29, r29
    LSL         r29, r29            ; message size in bits for the sha512 padding rule

    CALL        eddsa_e_load_message

    CMPI        r11, 128
    BRZ         eddsa_e_finish_pad_in_next_block

    CALL        eddsa_e_pad_mask

    CMPI        r9,  96
    BRZ         eddsa_e_finish_pad_in_r18
    MOV         r18, r29

    CMPI        r9,  64
    BRZ         eddsa_e_finish_pad_in_r19
    MOVI        r19, 0

    CMPI        r9,  32
    BRZ         eddsa_e_finish_pad_in_r20
    MOVI        r20, 0

eddsa_e_finish_pad_in_r21:
    AND         r21, r21, r5
    SBIT        r21, r21, r7
    JMP         eddsa_e_finish_last_hash

eddsa_e_finish_pad_in_r20:
    AND         r20, r20, r5
    SBIT        r20, r20, r7
    JMP         eddsa_e_finish_last_hash

eddsa_e_finish_pad_in_r19:
    AND         r19, r19, r5
    SBIT        r19, r19, r7
    JMP         eddsa_e_finish_last_hash
eddsa_e_finish_pad_in_r18:
    AND         r18, r18, r5
    SBIT        r18, r18, r7
    ANDI        r8,  r11, 0x10          ; mask bit 4 of msg size to check if new block is needed
    BRNZ        eddsa_e_finish_pad_in_r18_next_block
    OR          r18, r18, r29
    JMP         eddsa_e_finish_last_hash

eddsa_e_finish_pad_in_r18_next_block:
    HASH        r16, r18
    MOVI        r21, 0
    JMP         eddsa_e_finish_pad_next_block_continue

eddsa_e_finish_pad_in_next_block:
    HASH        r16, r18
    MOVI        r21, 0
    MOVI        r7,  255
    SBIT        r21, r21, r7
eddsa_e_finish_pad_next_block_continue:
    MOVI        r20, 0
    MOVI        r19, 0
    MOV         r18, r29

eddsa_e_finish_last_hash:
    LD          r31, ca_q25519
    HASH        r16, r18
    SWE         r16, r16            ; decode as little endian integer mod q
    SWE         r17, r17
    REDP        r25, r16, r17   

    MOVI        r0, ret_op_success
    MOVI        r1,  0
    JMP         set_res_word
