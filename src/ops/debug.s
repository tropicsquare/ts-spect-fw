; ==============================================================================
;  file    ops/debug.s
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
; Debug Ops
;
;   - X25519 debug
;   - ECDSA Sign debug
;   - EdDSA Constext Set debug
;
; ==============================================================================

op_x25519_dbg:
    LD      r19, x25519_dbg_input_priv
    LD      r16, x25519_dbg_input_pub

    CALL    x25519_full_masked

    ST      r11, x25519_dbg_output_r
    JMP     op_x25519_end

op_ecdsa_dbg:
    LD      r26, ecdsa_sign_dbg_input_d
    MOVI    r21, 0
    LD      r20, ecdsa_sign_dbg_input_w
    LD      r18, ecdsa_sign_dbg_input_z
    SWE     r18, r18
    LD      r16, ecdsa_sign_input_sch
    SWE     r16, r16
    LD      r17, ecdsa_sign_input_scn

    JMP     ecdsa_sign

op_eddsa_set_context_dbg:
    LD      r26, eddsa_set_context_dbg_input_s
    LD      r20, eddsa_set_context_dbg_input_prefix
    LD      r16, eddsa_set_context_input_sch
    SWE     r16, r16
    LD      r17, eddsa_set_context_input_scn
    MOVI    r0,  0
    ST      r0,  ca_eddsa_sign_internal_s1
    LD      r31, ca_q25519
    REDP    r0,  r0,  r26
    ST      r0,  ca_eddsa_sign_internal_s2

    MOVI    r0,  ret_op_success
    MOVI    r1,  0
    JMP     set_res_word
