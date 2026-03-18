; ==============================================================================
;  file    others/extend_tmac_mask.s
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
; Extends 256 bit value to 1024 using SHA512
;
; Input:
;   Value V to extend in r7
;
; Output:
;   Extended value E in (r10, r9, r8, r7)
;   Status in r30
;
; ==============================================================================

extend_tmac_mask:
    MOV         r8,  r7
    MOV         r9,  r7
    MOV         r10, r7
    HASH_IT
    HASH        r7,  r7 ; E1 = r8||r7 = SHA512(V||V||V||V)
    HASH        r9,  r7 ; E2 = SHA512(V||V||E')
    ; E = E2||E1
    RET
