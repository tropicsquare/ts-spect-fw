; ==============================================================================
;  file    ecc_math/curve25519/point_xdbl_curve25519.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Pseudo x-coordinate only doubling on Curve25519
; Follows Algorithm 2 from https://eprint.iacr.org/2017/212.pdf
; 
; Input:
;              X   Z
;   Point P = (r7, r8)
; 
; Output:
;   P = 2.P = (r7, r8)
; 
; Expects:
;   Curve25519 prime in r31
;   Curve25519 constant a2d4 = (Curve25519.A + 2) / 4 in r6
; 
;   xDBL(XP, ZP):
;       V1 = XP + ZP % p
;       V1 = V1 ** 2 % p
;       V2 = XP - ZP % p
;       V2 = V2 ** 2 % p
;       XP = V1 * V2 % p
;       V1 = V1 - V2 % p
;       V3 = a2d4 * V1 % p
;       V3 = V3 + V2 % p
;       ZP = V1 * V3 % p
;
; ==============================================================================

point_xdbl_curve25519:
    ADDP        r1,  r7,  r8                    ; V1 = XP + ZP % p
    MUL25519    r1,  r1,  r1                    ; V1 = V1 ** 2 % p
    SUBP        r2,  r7,  r8                    ; V2 = XP - ZP % p
    MUL25519    r2,  r2,  r2                    ; V2 = V2 ** 2 % p
    MUL25519    r7,  r1,  r2                    ; XP = V1 * V2 % p
    SUBP        r1,  r1,  r2                    ; V1 = V1 - V2 % p
    MUL25519    r3,  r6,  r1                    ; V3 = a2d4 * V1 % p
    ADDP        r3,  r3,  r2                    ; V3 = V3 + V2 % p
    MUL25519    r8,  r1,  r3                    ; ZP = V1 * V3 % p
    RET
    