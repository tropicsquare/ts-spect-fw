; ==============================================================================
;  file    ecc_math/p256/point_add_p256.s
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
; Point Addition on curve P-256
; Uses Algorithm 4 from https://eprint.iacr.org/2015/1060.pdf
; Input:
;   Point Q0 = (r9, r10, r11)
;   Point Q1 = (r12, r13, r14)
; Output:
;   Q1 = Q0 + Q1 = (r12, r13, r14)
;
; Expects:
;   p256 prime in r31
;   P-256 parameter b in r8
;
; Intermediate value registers:
;   r0-7
;
; ==============================================================================
point_add_p256:
    MUL256  r0,  r9,  r12
    MUL256  r1,  r10, r13
    MUL256  r2,  r11, r14
    ADDP    r3,  r9,  r10
    ADDP    r4,  r12, r13
    MUL256  r3,  r3,  r4
    ADDP    r4,  r0,  r1
    SUBP    r3,  r3,  r4
    ADDP    r4,  r10, r11
    ADDP    r5,  r13, r14
    MUL256  r4,  r4,  r5
    ADDP    r5,  r1,  r2
    SUBP    r4,  r4,  r5
    ADDP    r5,  r9,  r11
    ADDP    r6,  r12, r14
    MUL256  r5,  r5,  r6
    ADDP    r6,  r0,  r2
    SUBP    r6,  r5,  r6
    MUL256  r7,  r8,  r2
    SUBP    r5,  r6,  r7
    ADDP    r7,  r5,  r5
    ADDP    r5,  r5,  r7
    SUBP    r7,  r1,  r5
    ADDP    r5,  r1,  r5
    MUL256  r6,  r8,  r6
    ADDP    r1,  r2,  r2
    ADDP    r2,  r1,  r2
    SUBP    r6,  r6,  r2
    SUBP    r6,  r6,  r0
    ADDP    r1,  r6,  r6
    ADDP    r6,  r1,  r6
    ADDP    r1,  r0,  r0
    ADDP    r0,  r1,  r0
    SUBP    r0,  r0,  r2
    MUL256  r1,  r4,  r6
    MUL256  r2,  r0,  r6
    MUL256  r6,  r5,  r7
    ADDP    r13, r6,  r2
    MUL256  r5,  r3,  r5
    SUBP    r12, r5,  r1
    MUL256  r7,  r4,  r7
    MUL256  r1,  r3,  r0
    ADDP    r14, r7,  r1
    RET
