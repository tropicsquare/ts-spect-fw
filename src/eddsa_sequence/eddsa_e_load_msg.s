; ==============================================================================
;  file    eddsa_sequence/eddsa_e_load_msg.s
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
; Loads 128B EdDSA message chunk into (r18, r19, r20, r21) for e computation.
;
; ==============================================================================
eddsa_e_load_message:
    CALL        get_input_base
    ADDI        r30, r0,  eddsa_input_message

    LDR         r21, r30
    SWE         r21, r21
    ADDI        r30, r30, 32
    LDR         r20, r30
    SWE         r20, r20
    ADDI        r30, r30, 32
    LDR         r19, r30
    SWE         r19, r19
    ADDI        r30, r30, 32
    LDR         r18, r30
    SWE         r18, r18

    RET