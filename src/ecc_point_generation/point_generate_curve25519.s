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
; Point Generate on Curve25519. See str2point.md for detailed description.
;
; Input:
;   DST in ca_gfp_gen_dst
;
; Output:
;   Random point (x, z, y) on Curve25519 -- (r11, r12, r13)
;
; Expects:
;   Curve25519 prime in R31
;
; Modified registers:
;   r1, r2, r30
;
; Subroutines
;   hash_to_field
;   map_to_curve_elligator2_curve25519
;
; ==============================================================================

curve25519_point_generate:
    GRV         r2
    LD          r1,  ca_gfp_gen_dst
    CALL        hash_to_field                   ; r0 = x in GF(2^255 - 19)

    CALL        map_to_curve_elligator2_curve25519
    ; (r3, r7, r11, r8) = (xn, xd, y, 1)
    XORI        r30, r7, 0
    BRZ         curve25519_point_generate

    MUL25519    r13, r11, r7
    MOV         r11, r3
    MOV         r12, r7

    RET
