; Point Addition on Curve25519
; Uses Algorithm 1 from https://eprint.iacr.org/2015/1060.pdf with 
; birrational mapping between Curve25519 and W-25519
;
; Inputs:
;               X    Z    Y
;   Point Q1 = (r7,  r8,  r9)
;   Point Q2 = (r11, r12, r13)
;
; Output:
;   Point Q3 = Q1 + Q2 = (r11, r12, r13)
;
; Expects:
;   Curve25519 prime in r31
;

point_add_curve25519:
    LD          r20, ca_w25519_a
    LD          r21, ca_w25519_3b
    LD          r22, ca_curve25519_amap

    MUL25519    r5,  r22, r8
    ADDP        r5,  r5,  r7
    MUL25519    r6,  r22, r12
    ADDP        r6,  r6,  r11

    MUL25519    r0,  r5,  r6    ;
    MUL25519    r1,  r9,  r13   ;
    MUL25519    r2,  r8,  r12   ;
    ADDP        r3,  r5,  r9    ;
    ADDP        r4,  r6,  r13   ;
    MUL25519    r3,  r3,  r4    ;
    ADDP        r4,  r0,  r1    ;
    SUBP        r3,  r3,  r4    ;
    ADDP        r4,  r5,  r8    ;
    ADDP        r5,  r6,  r12   ;
    MUL25519    r4,  r4,  r5    ;
    ADDP        r5,  r0,  r2    ;
    SUBP        r4,  r4,  r5    ;
    ADDP        r5,  r9,  r8    ;
    ADDP        r11, r13, r12   ;
    MUL25519    r5,  r5,  r11   ;
    ADDP        r11, r1,  r2    ;
    SUBP        r5,  r5,  r11   ;
    MUL25519    r12, r20, r4    ;
    MUL25519    r11, r21, r2    ;
    ADDP        r12, r11, r12   ;
    SUBP        r11, r1,  r12   ;
    ADDP        r12, r1,  r12   ;
    MUL25519    r13, r11, r12   ;
    ADDP        r1,  r0,  r0    ;
    ADDP        r1,  r1,  r0    ;
    MUL25519    r2,  r20, r2    ;
    MUL25519    r4,  r21, r4    ;
    ADDP        r1,  r1,  r2    ;
    SUBP        r2,  r0,  r2    ;
    MUL25519    r2,  r20, r2    ;
    ADDP        r4,  r4,  r2    ;
    MUL25519    r0,  r1,  r4    ;
    ADDP        r13, r13, r0    ;
    MUL25519    r0,  r5,  r4    ;
    MUL25519    r11, r3,  r11   ;
    SUBP        r11, r11, r0    ;
    MUL25519    r0,  r3,  r1    ;
    MUL25519    r12, r5,  r12   ;
    ADDP        r12, r12, r0    ;

    MUL25519    r22, r22, r12
    SUBP        r11, r11, r22

    RET


