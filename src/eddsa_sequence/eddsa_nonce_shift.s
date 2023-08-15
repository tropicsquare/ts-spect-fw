; ==============================================================================
;  file    eddsa_sequence/eddsa_nonce_shift.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Left Shift of r1 <- r2 <- .. <- r6
;
; ==============================================================================

eddsa_nonce_shift:
    ROLIN       r1,  r1,  r2
    ROLIN       r2,  r2,  r3
    ROLIN       r3,  r3,  r4
    ROLIN       r4,  r4,  r5
    ROLIN       r5,  r5,  r6
    ROL8        r6,  r6
    RET