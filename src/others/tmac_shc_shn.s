; Compose 2 TMAC blocks out of Secure Channel Hash and Nonce (sch || scn)
; Updates TMAC
;
; Inputs:
;   Secure Channel Hash in r16
;   Secure Channel Nonce in r17

tmac_sch_scn:
    MOVI    r30, 28
;tmac_sch_scn_shift_scn_loop:
;    ROL8    r17, r17
;    SUBI    r30, r30, 1
;    BRNZ    tmac_sch_scn_shift_scn_loop

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
