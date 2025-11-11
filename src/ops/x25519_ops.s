; ==============================================================================
;  file    ops/x25519_ops.s
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
; X25519 Ops:
;   - Generate ETPRIV and ETPUB
;   - X25519(ETPRIV, EHPUB)
;   - X25519(ETPRIV, SHPUB)
;   - X25519(STPRIV, EHPUB)
;
; ==============================================================================

op_x25519_end:
    MOVI    r1,  32
    JMP     set_res_word

op_x25519_fail:
    MOVI    r31, 0
    CALL    clear_data_in
    CALL    clear_regs_before_return
    MOVI    r1,  0
    JMP     set_res_word

op_x25519_key_fail:
    MOVI    r0,  ret_key_err
    JMP     op_x25519_fail

op_x25519_ctx_fail:
    MOVI    r0,  ret_ctx_err
    JMP     op_x25519_fail

; ======================================================
;   x25519_kpair_gen
; ======================================================
op_x25519_kpair_gen:
    ; Store OP Link, nothing to check
    MOVI    r1,  x25519_kpair_gen_id
    ST      r1,  ca_op_link

    GRV     r19
    MOVI    r0,  7
    MOVI    r1,  255
    SBIT    r0,  r0, r1
    NOT     r0,  r0
    AND     r19, r0, r19
    MOVI    r1,  254
    SBIT    r19, r19, r1

    ST      r19, x25519_context_etpriv

    MOVI    r16, 9

    CALL    x25519_full_masked

    CMPI    r0,  ret_op_success
    BRNZ    op_x25519_fail
    ST      r11, x25519_kpair_gen_output_etpub
    JMP     op_x25519_end

; ======================================================
;   x25519_sc_et_eh
; ======================================================
op_x25519_sc_et_eh:
    ; Check and update OP Link context
    LD      r1,  ca_op_link
    CMPI    r1,  x25519_kpair_gen_id
    BRNZ    op_x25519_ctx_fail
    MOVI    r1,  x25519_sc_et_eh_id
    ST      r1,  ca_op_link

    LD      r19, x25519_context_etpriv
    LD      r16, x25519_sc_et_eh_input_ehpub
    ST      r16, x25519_context_ehpub

    CALL    x25519_full_masked

    CMPI    r0,  ret_op_success
    BRNZ    op_x25519_fail
    ST      r11, x25519_sc_et_eh_output_r1
    JMP     op_x25519_end

; ======================================================
;   x25519_sc_et_sh
; ======================================================
op_x25519_sc_et_sh:
    ; Check and update OP Link context
    LD      r1,  ca_op_link
    CMPI    r1,  x25519_sc_et_eh_id
    BRNZ    op_x25519_ctx_fail
    MOVI    r1,  x25519_sc_et_sh_id
    ST      r1,  ca_op_link

    LD      r1, x25519_sc_et_sh_input_slot
    LDK     r16, r1, 0x200
    BRE     op_x25519_key_fail

    LD      r19, x25519_context_etpriv

    CALL    x25519_full_masked

    CMPI    r0,  ret_op_success
    BRNZ    op_x25519_fail
    ST      r11, x25519_sc_et_sh_output_r2
    JMP     op_x25519_end

; ======================================================
;   x25519_sc_st_eh
; ======================================================
op_x25519_sc_st_eh:
    ; Check and clear OP Link context
    LD      r1,  ca_op_link
    CMPI    r1,  x25519_sc_et_sh_id
    BRNZ    op_x25519_ctx_fail
    MOVI    r1,  0
    ST      r1,  ca_op_link

    LD      r16, x25519_context_ehpub
    MOVI    r1, 0
    LDK     r19, r1, 0x000
    BRE     op_x25519_key_fail

    MOVI    r0,  7
    MOVI    r1,  255
    SBIT    r0,  r0, r1
    NOT     r0,  r0
    AND     r19, r0, r19
    MOVI    r1,  254
    SBIT    r19, r19, r1

    CALL    x25519_full_masked

    CMPI    r0,  ret_op_success
    BRNZ    op_x25519_fail
    ST      r11, x25519_sc_st_eh_output_r3

    MOVI    r31, 0
    CALL    clear_data_in
    CALL    clear_regs_before_return

    JMP     op_x25519_end
