; ==============================================================================
;  file    ecc_math/ed25519/point_order_check_ed25519.s
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
; Check if point P in extended coordinates is not of order h=8
;
;   [8].P != O
;
; Inputs:
;   Point P = (r7,  r8,  r9,  r10)
;
; Outputs:
;   success flag in r1 (0x0->PASS, 0xFFF->FAIL)
;
; Expects:
;   Ed25519 prime in r31
;
; Modified registers:
;   r1-4
;   !!! Destroys the point in r7-r10 !!!
;
; ==============================================================================

point_order_check_ed25519_success:
    MOVI    r1,  pass_val
    RET
point_order_check_ed25519:
    CALL    point_dbl_ed25519      ; [2].P
    CALL    point_dbl_ed25519      ; [4].P
    CALL    point_dbl_ed25519      ; [8].P

    XOR     r2,  r2,  r2    ; SET Zero Flag
    CALL    point_check_infinity_ed25519
    BRNZ    point_order_check_ed25519_success
point_order_check_ed25519_fail:
    MOVI    r1,  fail_val
    RET
