; ==============================================================================
;  file    ecc_math/curve25519/point_order_check_curve25519.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Check if point P in x-only coordinates is not of low-order (<= 8)
;
;   [8].P != O
;
; Inputs:
;   Point P.x = (r16)
;
; Outputs:
;   Sets Z flag if [8].P == O
;
; Expects:
;   Curve25519 prime in r31
;
; Modified registers:
;   r1,2,3,6,7,8
;
; Subroutines:
;   point_xdbl_curve25519
;
; ==============================================================================

point_order_check_curve25519:
    LD      r6,  ca_curve25519_a2d4

    MOV     r7,  r16
    MOVI    r8,  1

    CALL    point_xdbl_curve25519       ; [2].P
    CALL    point_xdbl_curve25519       ; [4].P
    CALL    point_xdbl_curve25519       ; [8].P

    XOR     r2,  r2,  r2                ; SET Zero Flag and r2 <- 0
    XOR     r8,  r8,  r2                ; Check r8 != 0

    RET
