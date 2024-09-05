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
; Compose 2 TMAC blocks out of Secure Channel Hash and Nonce (sch || scn)
; Updates TMAC
;
; Inputs:
;   Secure Channel Hash in r16
;   Secure Channel Nonce in r17
;
; ==============================================================================

tmac_sch_scn:
    MOVI    r30, 28

    SWE     r17, r17

    MOVI    r0,  0
    MOVI    r30, 18
tmac_sch_scn_shift_first_block_loop:
    ROLIN   r0,  r0,  r16
    ROLIN   r16, r16, r17
    ROL8    r17, r17
    SUBI    r30, r30, 1
    BRNZ    tmac_sch_scn_shift_first_block_loop

    TMAC_UP r0

    MOVI    r30, 18
tmac_sch_scn_shift_second_block_loop:
    ROLIN   r0,  r0,  r16
    ROL8    r16, r16
    SUBI    r30, r30, 1
    BRNZ    tmac_sch_scn_shift_second_block_loop

    TMAC_UP r0

    RET
