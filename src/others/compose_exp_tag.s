; Composes EXP_TAG for random point generation
; Input:
;   /
; Output:
;   EXP_TAG = "8000000000000000000000000000000000000000000000000000000000545301" in r3

compose_exp_tag:
    MOVI    r3,  0x054
    ROL8    r3,  r3
    ORI     r3,  r3, 0x053
    ROL8    r3,  r3
    ORI     r3,  r3, 0x001
    ROL8    r3,  r3
    ORI     r3,  r3, 0x080
    ROR8    r3,  r3
    RET