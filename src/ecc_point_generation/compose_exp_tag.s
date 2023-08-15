; ==============================================================================
;  file    ecc_point_generation/compose_exp_tag.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Composes EXP_TAG for random point generation
;
; Output:
;   EXP_TAG in r3
;
;   EXP_TAG = "8000000000000000000000000000000000000000000000000000000000545301" 
;
; ==============================================================================

compose_exp_tag:
    MOVI    r3,  0x054
    ROL8    r3,  r3
    ORI     r3,  r3,  0x053
    ROL8    r3,  r3
    ORI     r3,  r3,  0x001
    ROL8    r3,  r3
    ORI     r3,  r3,  0x080
    ROR8    r3,  r3
    RET