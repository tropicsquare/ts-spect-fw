; ==============================================================================
;  file    ecc_math/point_dbl_ed25519.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Point Doubling on curve Ed25519
; Follows algorithm from https://datatracker.ietf.org/doc/rfc8032/ Section 5.1.4.
;
; Algorithm:
;   A = X1^2
;   B = Y1^2
;   C = 2*Z1^2
;   H = A+B
;   E = H-(X1+Y1)^2
;   G = A-B
;   F = C+G
;   X3 = E*F
;   Y3 = G*H
;   T3 = E*H
;   Z3 = F*G
;
; Input:
;               X    Y    Z    T
;   Point Q1 = (r7,  r8,  r9,  r10)
;
; Output:
;   Q1 = 2.Q1
;
; Expects:
;   Ed25519 prime in r31
;
; Intermediate value registers:
;   r0-4
;
; ==============================================================================

point_dbl_ed25519:
    MUL25519    r0,  r7,  r7                    ; r0 = X1^2     r0 = A

    MUL25519    r1,  r8,  r8                    ; r1 = Y1^2     r1 = B

    MUL25519    r2,  r9,  r9                    ; r2 = Z1^2
    ADDP        r2,  r2,  r2                    ; r2 = r2 + r2  r2 = C

    ADDP        r3,  r0,  r1                    ; r3 = A+B      r3 = A+B = H
    
    ADDP        r4,  r7,  r8                    ; r4 = X1 + Y1
    MUL25519    r4,  r4,  r4                    ; r4 = r4 * r4
    SUBP        r4,  r3,  r4                    ; r4 = r3 - r4  r4 = H-(X1+Y1)^2 = E

    SUBP        r0,  r0,  r1                    ; r0 = r0 - r1  r0 = A-B = G
    
    ADDP        r1,  r2,  r0                    ; r1 = r2 + r0  r1 = C+G = F

    MUL25519    r7,  r4,  r1                    ; r7 = r4 * r1
    MUL25519    r9,  r0,  r1                    ; r10 = r0 * r1
    MUL25519    r8,  r0,  r3                    ; r8 = r0 * r3
    MUL25519    r10, r4,  r3                    ; r9 = r4 * r3

    RET