; ==============================================================================
;  file    eddsa_sequence/eddsa_nonce_init.s
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
; Initialize TMAC for deterministic nonce derivation with init string and SCH SCN
;
; Expected context:
;   Private key part 'prefix' <--- r20
;   Secure Channel Hash <--------- r16
;   Secure Channel Nonce <-------- r17
;
; ==============================================================================

op_eddsa_nonce_init:
    GRV         r7
    GRV         r8
    GRV         r9
    GRV         r10
_eddsa_tmac_it_bp_1:
    TMAC_IT     r7

    TMAC_IS     r20, tmac_dst_eddsa_sign

    CALL        tmac_sch_scn

    MOVI        r1,  0
    MOVI        r0,  ret_op_success
    JMP         set_res_word