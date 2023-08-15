; ==============================================================================
;  file    main_debug.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Top source for debug firmware.
;
;   - x25519_dbg
;   - ecdsa_sign_dbg
;   - eddsa_set_context_dbg + rest of EdDSA sequence
;
; ==============================================================================

.include mem_layouts/mem_layouts_includes.s
.include constants/spect_ops_constants.s
.include constants/spect_descriptors_constants.s
.include constants/l3_result_const.s
.include constants/spect_ops_status.s
_start:
    LD      r0, ca_spect_cfg_word
    ADDI    r0, r0, 0                           ; force bits [255:32] to 0
    MOVI    r4, 0xFF
    AND     r1, r0, r4                          ; mask SPECT_OP_ID to r1[7:0]

    CMPI    r1, x25519_dbg_id
    BRZ     op_x25519_dbg

    CMPI    r1, eddsa_set_context_dbg_id
    BRZ     op_eddsa_set_context_dbg

    CMPI    r1, ecdsa_sign_dbg_id
    BRZ     op_ecdsa_dbg

    CMPI    r1, eddsa_nonce_init_id
    BRZ     op_eddsa_nonce_init

    CMPI    r1, eddsa_nonce_update_id
    BRZ     op_eddsa_nonce_update

    CMPI    r1, eddsa_nonce_finish_id
    BRZ     op_eddsa_nonce_finish

    CMPI    r1, eddsa_R_part_id
    BRZ     op_eddsa_R_part

    CMPI    r1, eddsa_e_at_once_id
    BRZ     op_eddsa_e_at_once

    CMPI    r1, eddsa_e_prep_id
    BRZ     op_eddsa_e_prep

    CMPI    r1, eddsa_e_update_id
    BRZ     op_eddsa_e_update

    CMPI    r1, eddsa_e_finish_id
    BRZ     op_eddsa_e_finish

    CMPI    r1, eddsa_finish_id
    BRZ     op_eddsa_finish

invalid_op_id:
    MOVI    r2,  l3_result_invalid_cmd
    CALL    get_output_base
    STR     r2,  r0
    MOVI    r1,  0
    MOVI    r0,  ret_op_id_err
    JMP     set_res_word

get_input_base:
    MOVI    r0,  0
    RET
get_output_base:
    MOVI    r0,  0x10
    ROL8    r0,  r0
    RET

get_data_in_size:
    LD      r0,  ca_spect_cfg_word
    ROR8    r0,  r0
    ROR8    r0,  r0
    MOVI    r1,  0xFF
    ROL8    r1,  r1
    ORI     r1,  r1,  0xFF
    AND     r0,  r0,  r1
    RET

; ============================================================
; Debug Ops
; ============================================================
op_x25519_dbg:
    LD      r19, x25519_dbg_input_priv
    LD      r16, x25519_dbg_input_pub

    MOVI    r20, 0xD4

    CALL    x25519_full_masked

    ST      r11, x25519_dbg_output_r
    JMP     op_x25519_end

op_ecdsa_dbg:
    LD      r26, ecdsa_sign_dbg_input_d
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
    LD      r31, ca_q25519
    REDP    r0,  r0,  r26
    ST      r0,  ca_eddsa_sign_internal_smodq

    MOVI    r0,  ret_op_success
    JMP     set_res_word

; ============================================================
; Routine for setting  SPECT_RES_WORD field
; ============================================================
set_res_word:
    ROL8    r1,  r1
    ROL8    r1,  r1
    ADD     r0,  r0,  r1
    ST      r0,  ca_spect_res_word
    END

.include    routines_includes.s