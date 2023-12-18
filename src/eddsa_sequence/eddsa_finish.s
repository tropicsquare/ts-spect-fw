; ==============================================================================
;  file    eddsa_sequence/eddsa_finish.s
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
; Finish EdDSA signature
;
;   1) Compute S = r + e*rng + e*(s - rng)
;   2) Verify the computed signature
;
; ==============================================================================

op_eddsa_finish:
    LD          r31, ca_q25519

    MOVI        r0,  3
eddsa_finish_s_randomize:
    SUBI        r0,  r0,  1
    BRZ         eddsa_finish_randomize_fail
    GRV         r1
    MOVI        r0,  0
    REDP        r1,  r0,  r1
    XORI        r0,  r1,  0
    BRZ         eddsa_finish_s_randomize

    ; Compute S = r * e*s1 + e*s2
    LD          r26, ca_eddsa_sign_internal_smodq
    SUBP        r2,  r26, r1

    MULP        r1,  r1,  r25
    MULP        r2,  r2,  r25
    ADDP        r3,  r27, r1
    ADDP        r3,  r3,  r2

    ST          r3,  ca_eddsa_sign_internal_S

    ; decompres public key to extended coordinates
    LD          r31, ca_p25519
    LD          r6,  ca_ed25519_d
    LD          r12, ca_eddsa_sign_internal_A
    SWE         r12, r12
    CALL        point_decompress_ed25519

    XORI        r30, r1,  0
    BRNZ        eddsa_finish_fail
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    ; Compute e.A
    MOV         r28, r25

    CALL        spm_ed25519_short

    ST          r7,  ca_eddsa_sign_internal_EAx
    ST          r8,  ca_eddsa_sign_internal_EAy
    ST          r9,  ca_eddsa_sign_internal_EAz
    ST          r10, ca_eddsa_sign_internal_EAt

    ; Compute S.G
    LD          r28, ca_eddsa_sign_internal_S
    LD          r11, ca_ed25519_xG
    LD          r12, ca_ed25519_yG
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    CALL        spm_ed25519_short

    LD          r11, ca_eddsa_sign_internal_EAx
    LD          r12, ca_eddsa_sign_internal_EAy
    LD          r13, ca_eddsa_sign_internal_EAz
    LD          r14, ca_eddsa_sign_internal_EAt

    MOVI        r0,  0
    SUBP        r11, r0,  r11
    SUBP        r14, r0,  r14

    CALL        point_add_ed25519
    MOV         r7,  r11
    MOV         r8,  r12
    MOV         r9,  r13

    ; ENC(Q)
    CALL        point_compress_ed25519

    CALL        get_output_base
    ADDI        r30, r0,  eddsa_output_result

    LD          r4,  ca_eddsa_sign_internal_R
    
    ; ENC(Q) == ENC(R)
    XOR         r2,  r8,  r4
    BRNZ        eddsa_finish_fail

    MOVI        r2,  l3_result_ok
    STR         r2,  r30
    ADDI        r30, r0,  eddsa_finish_output_signature
    LD          r5,  ca_eddsa_sign_internal_S
    SWE         r4,  r4
    STR         r4,  r30
    ADDI        r30, r30,  0x20
    STR         r5,  r30

    MOVI        r0,  ret_op_success
    MOVI        r1,  48
    JMP         set_res_word

eddsa_finish_randomize_fail:
    CALL        get_output_base
    ADDI        r30, r0,  eddsa_output_result
    MOVI        r2,  l3_result_fail
    STR         r2,  r30
    MOVI        r0,  ret_grv_err
    MOVI        r1,  1
    JMP         set_res_word

eddsa_finish_fail:
    MOVI        r2,  l3_result_fail
    STR         r2,  r30

    MOVI        r0,  ret_eddsa_err_final_verify
    MOVI        r1,  1
    JMP         set_res_word
