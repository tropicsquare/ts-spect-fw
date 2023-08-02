op_eddsa_R_part:
    ; Load base point G
    LD          r31, ca_p25519
    LD          r21, ca_ed25519_xG
    LD          r22, ca_ed25519_yG
    MOVI        r25, 0xD7

    CALL        spm_ed25519_full_masked

    MOVI        r1,  0
    JMP         set_res_word
