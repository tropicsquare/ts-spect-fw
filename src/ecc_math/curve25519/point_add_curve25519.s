; ==============================================================================
;  file    ecc_math/curve25519/point_add_curve25519.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Point addition on Curve25519. Computes Q3 = Q1 + Q2, where:
;   Q1 != Q2
;   Q1 != O
;   Q2 != O
;
; Code using this routine shall ensure these constraints are satisfied.
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
; Modified registers
;   r0 - r6,
;   r11 - r13
;
; Algorithm:
;   U1 = X1 * Z2
;   U2 = X2 * Z1
;   S1 = Y1 * Z2
;   S2 = Y2 * Z1
;   H  = U2 - U1
;   R  = S2 - S1
;   ZZ = Z1 * Z2
;
;   NX = R^2 * ZZ - H^2 * (A * ZZ + U1 + U2)
;
;   X3 = H * NX
;   Y3 = R * (U1 * H^2 - NX) - S1 * H^3
;   Z3 = H^3 * ZZ
;
; ==============================================================================

point_add_curve25519:
    MUL25519    r0,  r7,  r12           ; r0 <- U1
    MUL25519    r1,  r11, r8            ; r1 <- U2
    MUL25519    r2,  r9,  r12           ; r2 <- S1
    MUL25519    r3,  r13, r8            ; r3 <- S2
    MUL25519    r4,  r8,  r12           ; r4 <- ZZ

    SUBP        r5,  r1,  r0            ; r5 <- H
    ADDP        r1,  r0,  r1            ; r1 <- U1 + U2             (last use of U2)
    SUBP        r3,  r3,  r2            ; r3 <- R                   (last use of S2)

    MUL25519    r6,  r5,  r5            ; r6 <- H^2
    MUL25519    r13, r6,  r5            ; r12 <- H^3

    MUL25519    r12, r13, r4            ; X3

    MUL25519    r2,  r2,  r13           ; r2 < S1 * H^3             (last use of S1 and H^3)

    MUL25519    r13, r3,  r3            ; r12 <- R^2
    MUL25519    r13, r13, r4            ; r12 <- R^2 * ZZ
    LD          r11, ca_curve25519_a
    MUL25519    r4,  r4,  r11           ; r4 <- A * ZZ              (last use of ZZ)
    ADDP        r4,  r4,  r1            ; r4 <- A * ZZ + U1 + U2    (last use of U1+U2)
    MUL25519    r4,  r4,  r6            ; r4 <- H^2(A * ZZ + U1 + U2)
    SUBP        r1,  r13, r4            ; r1 <- NX

    MUL25519    r11, r1,  r5            ; X3                        (last use of H)

    MUL25519    r4,  r0,  r6            ; r4 <- U1 * H^2            (last use of U1 and H^2)
    SUBP        r4,  r4,  r1            ; r4 <- U1 * H^2 - NX       (last use of NX)
    MUL25519    r4,  r4,  r3            ; r4 <- R * (U1 * H^2 - NX) (last use of R)

    SUBP        r13, r4,  r2            ; Y3

    RET


