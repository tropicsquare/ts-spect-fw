; ==============================================================================
;  file    src/eddsa_sequence/eddsa_r_part.s
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
; Computes R = r.G for EdDSA
;
; ==============================================================================

op_eddsa_R_part:
    ; Check and update OP Link context
    LD          r1,  ca_op_link
    CMPI        r1,  eddsa_nonce_finish_id
    BRNZ        eddsa_ctx_fail
    MOVI        r1,  eddsa_R_part_id
    ST          r1,  ca_op_link

    LD          r31, ca_p25519
    LD          r21, ca_ed25519_xG
    LD          r22, ca_ed25519_yG

    CALL        spm_ed25519_full_masked
    ; spm retcode check
    CMPI        r0,  ret_op_success
    BRNZ        eddsa_R_part_fail
    ; call check
    LD          r4, ca_call_check_level_2
    CMPI        r4, call_check_level_2_id
    MOVI        r4, 0
    ST          r4, ca_call_check_level_2
    BRNZ        eddsa_R_part_fail

    ; Encode R
    MOVI        r1,  1
    AND         r21, r21, r1
    ROR         r21, r21
    OR          r22, r22, r21
    SWE         r22, r22

    ST          r22, ca_eddsa_sign_internal_R

eddsa_R_part_pass:
    MOVI        r1,  0
    JMP         set_res_word

eddsa_R_part_fail:
    MOVI        r1,  ret_point_integrity_err
    JMP         set_res_word
