; ==============================================================================
;  file    ecc_math/curve25519/y_recovery_curve25519.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Y-Coordinate recovery for Curve25519
; Based on https://eprint.iacr.org/2017/212.pdf Algorithm 5
; Modified to work with P in projective coordinates (ZP != 1)
;
; Recovers y-coordinate of point Q = k.P based on:
;   - point P in projective coordinates (XP, ZP, YP)
;   - point Q in x-only coordinates (XQ, ZQ)
;   - point R = (k+1).P in x-only coordinates (XR, ZR)
;
; Inputs:
;   Point P = (r11, r12, r13)
;   Point Q = (r7, r8)
;   Point R = (r9, r10)
;
; Outputs:
;   Point Q = (XQ, ZQ, YQ) = (r7, r8, r9)
;
; Algorithm:
;   C = XQ * ZP
;   D = XP * ZQ
;   E = ZQ * ZP
;   F = (YP + YP) * ZQ * ZR
;   G = (AM + AM) * E
;
;   X0 = F * C % p
;   Y0 = ((C + D + G) * (XP * XQ + E) - G * E) * ZR - (C - D)**2 * XR
;   Z0 = F * E
;
; ==============================================================================

y_recovery_curve25519:
    MUL25519    r0,  r7,  r12 ; C
    MUL25519    r1,  r11, r8  ; D
    MUL25519    r2,  r8,  r12 ; E
    LD          r6,  ca_curve25519_a
    ADDP        r3,  r6,  r6  ;
    MUL25519    r3,  r3,  r2  ; G

    ADDP        r4,  r0,  r1  ;
    ADDP        r4,  r4,  r3  ; (C + D + G)

    MUL25519    r5,  r11, r7
    ADDP        r5,  r5,  r2  ; (XP * XQ + E)
    MUL25519    r4,  r4,  r5  ; (C + D + G) * (XP * XQ + E)
    MUL25519    r3,  r3,  r2  ; (G * E)
    SUBP        r4,  r4,  r3
    MUL25519    r4,  r4,  r10 ; ((C + D + G) * (XP * XQ + E) - (G * E)) * ZR
    SUBP        r1,  r0,  r1
    MUL25519    r1,  r1,  r1
    MUL25519    r1,  r1,  r9  ; ((C - D)^2) * XR
    SUBP        r9,  r4,  r1

    ADDP        r3,  r13, r13
    MUL25519    r3,  r3,  r8
    MUL25519    r3,  r3,  r10 ; F
    MUL25519    r7,  r3,  r0  ; (F * C)
    MUL25519    r8,  r3,  r2  ; (F * E)

    RET
