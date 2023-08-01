; ECDSA P-256 Sign
;
; Input:
;   Private Key Part w in r20
;   Private Key part d in 26
;   Secure Channel Hash in r16
;   Secure Channel Nonce in r17
;   Message Digest z in r18
;
; Output:
;   ECDSA Signature (R,S) = (r9, r0)
;   Status in r30

ecdsa_sign:
    GRV         r1
    GRV         r2
    GRV         r3
    GRV         r4
    TMAC_IT     r1
    TMAC_IS     r20, 0xB

    CALL        tmac_sch_scn

    MOVI        r0,  0
    MOVI        r30, 18
    MOV         r1,  r18
ecdsa_sign_tmac_z_first_loop:
    ROLIN       r0,  r0,  r1
    ROL8        r1,  r1
    SUBI        r30, r30, 1
    BRNZ        ecdsa_sign_tmac_z_first_loop

    TMAC_UP     r0

    MOVI        r30, 14
ecdsa_sign_tmac_z_second_loop:
    ROLIN       r0,  r0,  r1
    ROL8        r1,  r1
    SUBI        r30, r30, 1
    BRNZ        ecdsa_sign_tmac_z_second_loop

    MOVI        r30, 4
    MOVI        r1,  0
ecdsa_sign_tmac_padding_loop:
    ROLIN       r0,  r0,  r1
    ROL8        r1,  r1
    SUBI        r30, r30, 1
    BRNZ        ecdsa_sign_tmac_padding_loop

    MOVI        r30, 26
    SBIT        r0,  r0,  r30
    ORI         r0,  r0,  0x80

    TMAC_UP     r0

    TMAC_RD     r27

    ST          r18, ca_ecdsa_sign_internal_z

    LD          r31, ca_q256
    MOVI        r28, 0
    REDP        r27, r28, r27

    XORI        r0,  r27, 0
    BRZ         ecdsa_sign_fail_k

    LD          r22, ca_p256_xG
    LD          r23, ca_p256_yG

    MOVI        r25, 0xD8

    CALL        spm_p256_full_masked
    XORI        r0,  r0,  0
    BRNZ        ecdsa_sign_fail 

    LD          r31, ca_q256
    MOVI        r0, 0
    REDP        r22, r0, r22
    XORI        r0, r22, 0
    BRZ         ecdsa_sign_fail_r
    MOVI        r1,  3

ecdsa_sign_mask_k:
    SUBI        r1,  r1, 1
    BRZ         ecdsa_fail_k_mask
    GRV         r25                     ; t
    MOVI        r0,  0
    REDP        r25, r0,  r25
    XORI        r25, r25, 0
    BRZ         ecdsa_sign_mask_k       ; t must not be 0
    MULP        r1,  r25, r27
    CALL        inv_q256                ; (kt)^(-1)

    LD          r18, ca_ecdsa_sign_internal_z
    MULP        r10, r18, r25           ; zt
    MULP        r11, r22, r25           ; rt
    MULP        r11, r26, r11           ; rtd
    ADDP        r10, r10, r11           ; zt + rtd
    MULP        r10, r1,  r10           ; (zt + rtd) / (kt)

    XORI        r0, r10,  0
    BRZ         ecdsa_sign_fail_s

    MOVI        r3,  ret_op_success
    MOVI        r1,  48

ecdsa_sign_end:
    CALL        get_output_base

    ADDI        r30, r0,  ecdsa_output_result
    STR         r2,  r30
    CMPI        r3,  ret_op_success
    BRNZ        ecdsa_sign_end_not_store

    ADDI        r30, r0,  ecdsa_sign_output_R
    STR         r22, r30

    ADDI        r30, r0,  ecdsa_sign_output_S
    STR         r10, r30

ecdsa_sign_end_not_store:
    MOV         r0,  r3
    JMP         set_res_word

ecdsa_sign_fail_k:
    MOVI        r3,  ret_ecdsa_err_inv_nonce
    JMP         ecdsa_sign_fail
ecdsa_sign_fail_r:
    MOVI        r3,  ret_ecdsa_err_inv_r
    JMP         ecdsa_sign_fail
ecdsa_sign_fail_s:
    MOVI        r3,  ret_ecdsa_err_inv_s
    JMP         ecdsa_sign_fail
ecdsa_fail_k_mask:
    MOVI        r3,  ret_grv_err
    JMP         ecdsa_sign_fail
ecdsa_sign_fail:
    MOVI        r2,  l3_result_fail
    MOVI        r1,  1
    JMP         ecdsa_sign_end


