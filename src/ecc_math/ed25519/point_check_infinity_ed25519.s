; ==============================================================================
;  file    ecc_math/ed25519/point_check_infinity_ed25519.s
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
; Check if point P is the point at infinity O
;
;   P != O
;
; Inputs:
;   Point P = (r7,  r8,  r9,  r10)
;
; Outputs:
;   P == O : Z flag <- 1
;   P != O : Z flag <- 0
;
; Expects:
;   Ed25519 prime in r31
;
; Modified registers:
;   r1-4
;
; ==============================================================================

point_check_infinity_ed25519:
    XOR         r2,  r7,  r4    ; X == 0
    XOR         r3,  r10, r4    ; T == 0
    XOR         r4,  r8,  r9    ; Y == Z
    OR          r1,  r2,  r3
    OR          r1,  r1,  r4
    RET