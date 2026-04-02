; ==============================================================================
;  file    eddsa_sequence/eddsa_finish.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Finish EdDSA signature
;
;   1) Compute S = r + e*s1 + e*s2
;   2) Verify the computed signature
;
; ==============================================================================

op_eddsa_finish:
    ; Check and Clear OP Link context
    LD          r1,  ca_op_link
    CMPI        r1,  eddsa_e_finish_id
    BRZ         eddsa_finish_ctx_ok
    CMPI        r1,  eddsa_e_at_once_id
    BRNZ        eddsa_ctx_fail
eddsa_finish_ctx_ok:
    MOVI        r1,  0
    ST          r1,  ca_op_link

    LD          r31, ca_q25519

eddsa_finish_s_randomize:
    ; Compute S = r + e*s1 + e*s2
    LD          r26, ca_eddsa_sign_internal_s1
    LD          r2,  ca_eddsa_sign_internal_s2

    MULP        r1,  r26, r25
    MULP        r2,  r2,  r25
    ADDP        r3,  r27, r1
    ADDP        r3,  r3,  r2

    ST          r3,  ca_eddsa_sign_internal_S

; ==============================================================================
;   Verify the signature
; ==============================================================================
    CALL        eddsa_verify_e
    ; Call check
    LD          r4, ca_call_check_level_1
    CMPI        r4, call_check_level_1_id
    MOVI        r4, 0
    ST          r4, ca_call_check_level_1
    BRNZ        ecdsa_fail_verify
    ; Check retval
    CMPI        r30, pass_val
    BRNZ        eddsa_finish_fail_verify

; ==============================================================================
;   Finish
; ==============================================================================
    CALL        get_output_base
    ADDI        r30, r0,  eddsa_output_result

    MOVI        r2,  l3_result_ok
    STR         r2,  r30
    ADDI        r30, r0,  eddsa_finish_output_signature
    SWE         r5,  r5
    STR         r5,  r30
    LD          r5,  ca_eddsa_sign_internal_S
    ADDI        r30, r30,  0x20
    STR         r5,  r30

    MOVI        r0,  ret_op_success
    MOVI        r1,  80
    JMP         eddsa_finish_clean

eddsa_finish_fail_invalid_pubkey:
    MOVI        r1,  ret_eddsa_err_final_verify
    JMP         eddsa_finish_fail

eddsa_finish_fail_verify:
    MOVI        r1,  ret_eddsa_err_final_verify
    JMP         eddsa_finish_fail

eddsa_ctx_fail:
    MOVI        r1,  ret_ctx_err
    JMP         eddsa_finish_fail

eddsa_finish_fail:
    ; Clear OP Link context
    MOVI        r2,  0
    ST          r2,  ca_op_link
    ; Set L3 Result
    CALL        get_output_base
    ADDI        r30, r0,  eddsa_output_result
    MOVI        r2,  l3_result_fail
    STR         r2,  r30

    MOV         r0,  r1
    MOVI        r1,  1
    JMP         eddsa_finish_clean

eddsa_finish_clean:
    MOVI        r31, 0
    CALL        clear_data_in
    CALL        clear_regs_before_return
    JMP         set_res_word
