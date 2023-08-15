; ==============================================================================
;  file    ecc_math/curve25519/point_check_curve25519.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Check if point P = (X, Z, Y) is a valid Curve25519 point
;
;           Z Y^2 == X(X^2 + Z(AX + Z))
;
; Input:
;               X   Z   Y
;   Point P = (r7, r8, r9)
;
; Sets Zero flag if P is a valid point
;
; ==============================================================================

point_check_curve25519:
    MUL25519    r0, r9, r9
    MUL25519    r0, r0, r8

    LD          r1, ca_curve25519_a
    MUL25519    r1, r1, r7
    ADDP        r1, r1, r8
    MUL25519    r1, r1, r8
    MUL25519    r2, r7, r7
    ADDP        r1, r1, r2
    MUL25519    r1, r1, r7

    XOR         r0, r0, r1
    RET
