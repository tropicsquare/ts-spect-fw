; ==============================================================================
;  file    ecc_crypto/ecdsa_sign.s
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
; ECDSA P-256 Sign
;
; Input:
;   Private Key part 'w' in r20
;   Private Key part 'd1' in r21
;   Private Key part 'd2' in r26
;   Secure Channel Hash in r16
;   Secure Channel Nonce in r17
;   Message Digest z in r18
;
; Output:
;   ECDSA Signature (R,S) = (r9, r10)
;   Status in r30
;
; ==============================================================================

ecdsa_sign:
    GRV         r3
    GRV         r4
    GRV         r5
    GRV         r6

    TMAC_IT     r3
    TMAC_IS     r20, tmac_dst_ecdsa_sign

    CALL        tmac_sch_scn

    MOVI        r0,  0
    MOVI        r30, 18
    MOV         r1,  r18

; ==============================================================================
;   Compute Nonce k
;       k1 = int(TMAC(w, sch || scn || z, 0xB))
;       k2 = int(TMAC(k1, "", 0xB))
;       k = (k1 + (k2 * 2^256)) mod q
; ==============================================================================

; Get k1
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

; Get k2 from k1
    ; TODO: Using previous mask is not optimal. Come up with better solution how to avoid 4 GRVs
    TMAC_IT     r3

    TMAC_IS     r27, tmac_dst_ecdsa_sign

    MOVI        r1,  0x04
    MOVI        r30, 17
ecdsa_sign_tmac_padding_loop_k2:
    ROL8        r1,  r1
    SUBI        r30, r30, 1
    BRNZ        ecdsa_sign_tmac_padding_loop_k2
    ORI         r1, r1, 0x80

    TMAC_UP     r1
    TMAC_RD     r28

    ST          r18, ca_ecdsa_sign_internal_z

    LD          r31, ca_q256
    REDP        r27, r28, r27

    XORI        r0,  r27, 0
    BRZ         ecdsa_sign_fail_k

; ==============================================================================
;   Compute r = [k.G]x
; ==============================================================================

    LD          r22, ca_p256_xG
    LD          r23, ca_p256_yG

    CALL        spm_p256_full_masked
    MOV         r3,  r0
    CMPI        r0,  0
    BRNZ        ecdsa_sign_fail

    LD          r31, ca_q256
    MOVI        r0, 0
    REDP        r22, r0, r22
    XORI        r0, r22, 0
    BRZ         ecdsa_sign_fail_r

; ==============================================================================
;   Compute s = (z + r*d)/k
;   Masked with t as (z*t + t*r*d1 + t*r*d2) * (k*t)^(-1)
; ==============================================================================

ecdsa_sign_mask_k:
    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field
    MOV         r25, r0                         ; t
    ORI         r25, r25, 1                     ; force t to be even -> not 0
    MULP        r1,  r25, r27
    CALL        inv_q256                        ; (kt)^(-1)

    LD          r18, ca_ecdsa_sign_internal_z
    MULP        r10, r18, r25                   ; zt
    MULP        r11, r22, r25                   ; rt
    MULP        r12, r26, r11                   ; rtd1
    MULP        r13, r21, r11                   ; rtd2
    ADDP        r11, r12, r13                   ; rtd1 + rtd2 = rtd
    ADDP        r10, r10, r11                   ; zt + rtd
    MULP        r10, r1,  r10                   ; (zt + rtd) / (kt)

    XORI        r0, r10,  0
    BRZ         ecdsa_sign_fail_s

; ==============================================================================
;   Verify the signature
; ==============================================================================

    ST          r10, ca_ecdsa_sign_internal_s
    MOV         r1,  r10
    CALL        inv_q256                        ; r1 = s^(-1)

    MULP        r28, r18, r1                    ; r2 = e s^(-1) = u1
    MULP        r27, r22, r1                    ; r3 = r s^(-1) = u2

    LD          r31, ca_p256
    ; P1 = u1.G to (r15, r16, r17)
    LD          r12, ca_p256_xG
    LD          r13, ca_p256_yG
    MOVI        r14, 1

    CALL        spm_p256_short

    MOV         r15, r9
    MOV         r16, r10
    MOV         r17, r11

    ; P1 = u2.A to (r9, r10, r11)
    LD          r12, ca_ecdsa_sign_internal_Ax
    LD          r13, ca_ecdsa_sign_internal_Ay
    MOVI        r14, 1

    MOV         r28, r27
    CALL        spm_p256_short

    ; check if P1x == P2x
    MUL256      r2,  r15, r11
    MUL256      r3,  r9,  r17
    XOR         r0,  r2,  r3
    BRNZ        eddsa_sign_verify_continue_add  ; P1x != P2x -> use add
    MUL256      r2,  r16, r11
    MUL256      r3,  r10, r17
    XOR         r0,  r2,  r3
    BRNZ        ecdsa_fail_verify               ; P1x == -P2x -> fail
    ; P1x == P2x -> use dbl
eddsa_sign_verify_continue_dbl:
    CALL        point_dbl_p256
    MOV         r12, r9
    MOV         r13, r10
    MOV         r14, r11
    JMP         eddsa_sign_verify_continue_dbladd

eddsa_sign_verify_continue_add:
    MOV         r12, r15
    MOV         r13, r16
    MOV         r14, r17

    CALL        point_add_p256
eddsa_sign_verify_continue_dbladd:

    MOV         r1,  r14
    CALL        inv_p256
    MUL256      r12, r12, r1

    LD          r31, ca_q256
    MOVI        r0,  0
    REDP        r12, r0,  r12

    XOR         r1,  r12, r22
    BRNZ        ecdsa_fail_verify

    MOVI        r3,  ret_op_success
    MOVI        r2,  l3_result_ok
ecdsa_sign_end:
    CALL        get_output_base

    ADDI        r30, r0,  ecdsa_output_result
    STR         r2,  r30
    CMPI        r3,  ret_op_success
    MOVI        r1,  1
    BRNZ        ecdsa_sign_end_not_store
    MOVI        r1,  80

    ADDI        r30, r0,  ecdsa_sign_output_signature
    SWE         r22, r22
    STR         r22, r30

    ADDI        r30, r30, 0x20
    LD          r10, ca_ecdsa_sign_internal_s
    SWE         r10, r10
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
ecdsa_fail_verify:
    MOVI        r3,  ret_ecdsa_err_final_verify
    JMP         ecdsa_sign_fail
ecdsa_sign_fail:
    MOVI        r2,  l3_result_fail
    MOVI        r1,  1
    JMP         ecdsa_sign_end
