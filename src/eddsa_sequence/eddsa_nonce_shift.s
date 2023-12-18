; ==============================================================================
;  file    eddsa_sequence/eddsa_nonce_shift.s
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
; Left Shift of r1 <- r2 <- .. <- r6
;
; ==============================================================================

eddsa_nonce_shift:
    ROLIN       r1,  r1,  r2
    ROLIN       r2,  r2,  r3
    ROLIN       r3,  r3,  r4
    ROLIN       r4,  r4,  r5
    ROLIN       r5,  r5,  r6
    ROL8        r6,  r6
    RET