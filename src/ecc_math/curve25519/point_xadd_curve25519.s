; ==============================================================================
;  file    ecc_math/curve25519/point_xadd_curve25519.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Differential x-coordinate only addition on Curve25519
; Follows Algorithm 1 from https://eprint.iacr.org/2017/212.pdf
;
; Input:
;               X    Z
;   Point P = (r7,  r8)     -> x(P)
;   Point Q = (r9,  r10)    -> x(Q)
;   Point R = (r11, r12)    -> x(P - Q)
; 
; Output:
;   Q = P + Q = (r9, r10) -> x(P + Q)
; 
; Expects:
;   Curve25519 prime in r31

;   xADD(XP, ZP, XQ, ZQ, XR, ZR = 1):
;       V0 = XP + ZP
;       V1 = XQ - ZQ
;       V1 = V1 * V0
;       V0 = XP - ZP
;       V2 = XQ + ZQ
;       V2 = V2 * V0
;       V3 = V1 + V2
;       V3 = V3 ** 2
;       V4 = V1 - V2
;       V4 = V4 ** 2
;       XQ = ZR * V3
;       ZQ = XR * V4
;
; ==============================================================================

point_xadd_curve25519:
    ADDP        r0,  r7,  r8    ;   V0 = XP + ZP
    SUBP        r1,  r9,  r10   ;   V1 = XQ - ZQ
    MUL25519    r1,  r1,  r0    ;   V1 = V1 * V0
    SUBP        r0,  r7,  r8    ;   V0 = XP - ZP
    ADDP        r2,  r9,  r10   ;   V2 = XQ + ZQ
    MUL25519    r2,  r2,  r0    ;   V2 = V2 * V0
    ADDP        r3,  r1,  r2    ;   V3 = V1 + V2
    MUL25519    r3,  r3,  r3    ;   XQ = V3 ** 2
    SUBP        r4,  r1,  r2    ;   V4 = V1 - V2
    MUL25519    r4,  r4,  r4    ;   V4 = V4 ** 2
    MUL25519    r9,  r3,  r12   ;   XQ = ZR * V3
    MUL25519    r10, r11, r4    ;   ZQ = XR * V4
    RET
