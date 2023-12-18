; ==============================================================================
;  file    eddsa_sequence/eddsa_nonce_load_msg.s
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
; Loads 144B EdDSA message chunk into (r2, .., r6) for EdDSA nonce derivation.
;
; ==============================================================================

eddsa_nonce_load_msg:
    CALL        get_input_base
    ADDI        r30, r0,  eddsa_input_message
    MOVI        r1,  0
    LDR         r2,  r30
    ADDI        r30, r30, 32
    LDR         r3,  r30
    ADDI        r30, r30, 32
    LDR         r4,  r30
    ADDI        r30, r30, 32
    LDR         r5,  r30
    ADDI        r30, r30, 32
    LDR         r6,  r30

    SWE         r2,  r2
    SWE         r3,  r3
    SWE         r4,  r4
    SWE         r5,  r5
    SWE         r6,  r6
    RET