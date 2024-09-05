; ==============================================================================
;  file    ecc_point_generation/point_generate_curve25519.s
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
; Point Generate on Curve25519
;
; Input:
;   0x02 || DST || 0x1E in r1
;
; Output:
;   Random point (x, z, y) on Curve25519 -- (r11, r12, r13)
;
; Expects:
;   Curve25519 prime in R31
;
; Intermediate value registers:
;   r0,..,r14
;
; See str2point.md for detailed description.
;
; ==============================================================================

curve25519_point_generate:
    GRV         r2
    CALL        hash_to_field                   ; r0 = x in GF(2^255 - 19)

    CALL        map_to_curve_elligator2_curve25519
    ; (r3, r7, r11, r8) = (xn, xd, y, 1)
    XORI        r30, r7, 0
    BRZ         curve25519_point_generate

    MUL25519    r13, r11, r7
    MOV         r11, r3
    MOV         r12, r7

    RET
