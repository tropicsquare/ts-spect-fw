; ==============================================================================
;  file    ecc_point_generation/hash_to_field.s
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
; Returns 256-bit random string using 2 GRV instructions.
;
; Rationale:
;   It is possible that the external random source does not provide full 256-bit
;   entropy, but a bit less (we expect at least 168-bit).
;   Therefore, in order to get a good quality random bit-string (e.g. for key
;   generation) we fetch 512 bits (so we expect total entropy > 2 x 168 bits)
;   and use SHA-512 to combine them to get the resulting 256-bit random string.
;
; Outputs:
;   random bit-string in r19
;
; Modified registers:
;   r0..3
;
; ==============================================================================

get_secure_random:
    GRV     r3
    GRV     r2
    MOVI    r1,  1
    ROR     r1,  r1
    MOVI    r0,  512

    HASH_IT
    HASH    r0,  r0

    XOR     r19, r0,  r1

    RET
