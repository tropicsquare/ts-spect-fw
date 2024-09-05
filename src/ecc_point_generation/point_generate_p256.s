; ==============================================================================
;  file    ecc_point_generation/point_generate_p256.s
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
; Point Generate on NIST curve P-256
;
; Input:
;   DST in ca_gfp_gen_dst
;
; Output:
;   Random point (x, y, z) on cirve P-256 -- (r17, r18, r19)
;
; Expects:
;   P-256 prime in r31
;
; Intermediate registers:
;   r0, ..., r
;
; See spect_fw/str2point.md for detailed description.
;
; ==============================================================================
p256_point_generate:
    LD      r1, ca_gfp_gen_dst
    GRV     r2
    CALL    hash_to_field

    CALL    map_to_curve_simple_swu
    XORI    r30, r19, 0
    BRZ     p256_point_generate

    RET
