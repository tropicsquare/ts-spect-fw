; ==============================================================================
;  file    src/eddsa_sequence/eddsa_r_part.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Computes R = r.G for EdDSA
;
; ==============================================================================

op_eddsa_R_part:
    ; Load base point G
    LD          r31, ca_p25519
    LD          r21, ca_ed25519_xG
    LD          r22, ca_ed25519_yG
    MOVI        r25, 0xD7

    CALL        spm_ed25519_full_masked

    MOVI        r1,  1
    AND         r21, r21, r1
    ROR         r21, r21
    OR          r22, r22, r21
    SWE         r22, r22

    ST          r22, ca_eddsa_sign_internal_R

    MOVI        r1,  0
    JMP         set_res_word
