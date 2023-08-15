; ==============================================================================
;  file    eddsa_sequence/eddsa_nonce_init.s
;  author  vit.masek@tropicsquare.com
;  license TODO
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
    GRV         r1
    GRV         r2
    GRV         r3
    GRV         r4
    TMAC_IT     r1

    TMAC_IS     r20, 0xC

    CALL        tmac_sch_scn

    MOVI        r1,  0
    MOVI        r0,  ret_op_success
    JMP         set_res_word