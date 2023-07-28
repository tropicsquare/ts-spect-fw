.include ../src/mem_leyouts/mem_leyouts_includes.s
.include ../src/constants/spect_ops_constants.s
.include ../src/constants/spect_descriptors_constants.s
.include ../src/constants/l3_result_const.s
.include ../src/constants/spect_ops_status.s

_start:
    LD      r0,  ca_spect_cfg_word
    MOVI    r2, 0xFF
    AND     r1, r0, r2

op_id_check_x25519_dbg:
    CMPI    r1,  x25519_dbg_id
    BRZ     op_x25519_dbg

op_id_check_ecdsa_sign_dbg:
    CMPI    r1,  ecdsa_sign_dbg_id
    BRZ     op_ecdsa_sign_dbg

op_id_check_eddsa_sign_dbg:
    CMPI    r1,  eddsa_sign_dbg_id
    BRZ     op_eddsa_sign_dbg

    MOVI    r0,  ret_op_id_err
    ST      r0,  ca_spect_res_word
    END

op_x25519_dbg:
    LD      r16, x25519_dbg_input_pub
    LD      r19, x25519_dbg_input_priv

    MOVI    r0,  7
    MOVI    r1,  255
    SBIT    r0,  r0, r1
    NOT     r0,  r0
    AND     r19, r0, r19
    MOVI    r1,  254
    SBIT    r19, r19, r1

    MOVI    r20, 0xD3

    CALL    x25519_full_masked

    CMPI    r0,  0
    MOVI    r1,  0
    BRNZ    set_res_word
    ST      r11, x25519_kpair_gen_output_etpub
    MOVI    r1,  32
    JMP     set_res_word

op_ecdsa_sign_dbg:
    JMP     set_res_word

op_eddsa_sign_dbg:
    JMP     set_res_word

; ============================================================
; Routines for geting fields from SPECT_CFG_WORD
; ============================================================
get_input_base:
    LD      r0, ca_spect_cfg_word
    MOVI    r1, 0xF0
    ROL8    r1, r1
    AND     r0, r0, r1
    RET
get_output_base:
    LD      r0, ca_spect_cfg_word
    MOVI    r1, 0xF0
    ROL8    r1, r1
    LSL     r0, r0
    LSL     r0, r0
    LSL     r0, r0
    LSL     r0, r0
    AND     r0, r0, r1
    RET

; ============================================================
; Routine for setting  SPECT_RES_WORD field
; ============================================================
set_res_word:
    ROL8    r1, r1
    ROL8    r1, r1
    ADD     r0, r0, r1
    ST      r0, ca_spect_res_word
    END

.include ../src/routines_includes.s