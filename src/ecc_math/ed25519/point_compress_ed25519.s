; ==============================================================================
;  file    ecc_math/ed25519/point_compress_ed25519.s
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
; Compress Ed25519 point in extended coordinates
; Based on https://datatracker.ietf.org/doc/rfc8032/ Section 5.1.2
;
; Input:
;               X    Y    Z
;   Point P = (r7,  r8,  r9)
;
; Output:
;   Compressed point Q = ENC(P) in r8
;
; Modified registers:
;   r1,7,8
;
; Subroutines:
;   inv_p25519
;
; ==============================================================================

point_compress_ed25519:
    ; back to affine coordinates
    MOV         r1,  r9
    CALL        inv_p25519
    MUL25519    r7,  r7,  r1
    MUL25519    r8,  r8,  r1

    ; ENC(r7, r8)
    MOVI        r1,  1
    AND         r7,  r7,  r1
    ROL         r8,  r8
    OR          r8,  r8,  r7
    ROR         r8,  r8
    SWE         r8,  r8
    RET