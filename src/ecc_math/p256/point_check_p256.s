; ==============================================================================
;  file    ecc_math/p256/point_check_p256.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Check if point P is a valid P-256 point
;
;       Y^2*Z = X^3 + a*X*Z^2 + b*Z^3
;
; Inputs:
;   Point P = (r9, r10, r11)
;
; Outputs:
;   Sets Z flag if point is valid
;
; Expects:
;   P256 prime in r31
;
; ==============================================================================

point_check_p256:
    LD      r0,  ca_p256_a
    LD      r1,  ca_p256_b

    MUL256  r3,  r10, r10                       ; Y^2
    MUL256  r3,  r3,  r11                       ; Y^2 * Z

    MUL256  r2,  r9,  r9
    MUL256  r2,  r2,  r9                        ; X^3

    MUL256  r4,  r11, r11                       ; Z^2
    MUL256  r5,  r4,  r11                       ; Z^3

    MUL256  r0,  r0,  r9
    MUL256  r0,  r0,  r4                        ; a*X*Z^2

    MUL256  r1,  r1,  r5                        ; b*Z^3

    ADDP    r0,  r0,  r1
    ADDP    r0,  r0,  r2                        ; X^3 + a*X*Z^2 + b*Z^3

.ifdef SPECT_ISA_VERSION_1
    SUBP    r0,  r0,  r3
    CMPA    r0,  0
.endif
.ifdef SPECT_ISA_VERSION_2
    XOR     r0,  r0,  r3
.endif

    RET
