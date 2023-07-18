.include mem_leyouts/mem_leyouts_includes.s
.include spect_ops_constants.s
.include spect_descriptors_constants.s
.include spect_ops_status.s
_start:
    LD      r0, ca_spect_cfg_word
    ADDI    r0, r0, 0               ; force bits [255:32] to 0
    MOVI    r4, 0xFF
    AND     r1, r0, r4              ; mask SPECT_OP_ID to r1[7:0]
    ANDI    r4, r1, 0xF0            ; get only op type id

op_id_check_clear:
    CMPI r4, clear_id
    BRZ  op_clear

op_id_check_sha512:
    CMPI r4, sha512_id
    BRZ  op_sha512

op_id_check_ecc_key:
    CMPI r4, ecc_key_id
    BRZ  op_ecc_key

op_id_check_x25519:
    CMPI r4, x25519_id
    BRZ  op_x25519

op_id_check_eddsa:
    CMPI r4, eddsa_id
    BRZ  op_eddsa

op_id_check_ecdsa:
    CMPI r4, ecdsa_id
    BRZ  op_ecdsa

; ============================================================
op_id_debug:
    MOVI    r30, 0
    ST      r30, ca_spect_res_word
    END

; ============================================================
op_clear:
    MOVI    r30, ret_op_success
    ST      r30, ca_spect_res_word
    MOVI    r30, clear_id
    JMP     set_res_word
; ============================================================
op_sha512:
    CMPI    r1, sha512_init_id
    BRZ     op_sha512_init

    CMPI    r1, sha512_update_id
    BRZ     op_sha512_update

    CMPI    r1, sha512_final_id
    BRZ     op_sha512_final

    JMP     invalid_op_id
; ============================================================
op_ecc_key:
    CMPI    r1, ecc_key_gen_id
    BRZ     op_ecc_key_gen

    CMPI    r1, ecc_key_store_id
    BRZ     op_ecc_key_store

    CMPI    r1, ecc_key_read_id
    BRZ     op_ecc_key_read

    CMPI    r1, ecc_key_erase_id
    BRZ     op_ecc_key_erase

    JMP     invalid_op_id

; ============================================================
op_x25519:
    CMPI    r1, x25519_kpair_gen_id
    BRZ     op_x25519_kpair_gen

    CMPI    r1, x25519_sc_et_eh_id
    BRZ     op_x25519_sc_et_eh

    CMPI    r1, x25519_sc_et_sh_id
    BRZ     op_x25519_sc_et_sh

    CMPI    r1, x25519_sc_st_eh_id
    BRZ     op_x25519_sc_st_eh

    JMP     invalid_op_id

; ============================================================
op_eddsa:
    CMPI    r1, eddsa_set_context_id
    BRZ     op_eddsa_set_context

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

    CMPI    r1, eddsa_verify_id
    BRZ     op_eddsa_verify

    JMP     invalid_op_id

; ============================================================
op_ecdsa:
    CMPI    r1, ecdsa_sign_id
    BRZ     op_ecdsa_sign

    JMP     invalid_op_id

; ============================================================


; ============================================================
; Curve25519 Random Point Generation
;next_cmd_4:
;    CMPI r0, curve25519_rpg_id
;    BRNZ next_cmd_5
;    LD      r1, ca_dst_template
;    LD      r2, 0x0020              ; DST ID
;    OR      r1, r1, r2
;    ROL8    r1, r1
;    CALL    curve25519_point_generate
;    ST      r11, 0x1000 
;    ST      r13, 0x1020
;    ST      r12, 0x1040
;    END 
; ============================================================
; ============================================================
; Ed25519 Random Point Generation
;next_cmd_5:
;    CMPI r0, ed25519_rpg_id
;    BRNZ next_cmd_end
;    LD      r1, ca_dst_template
;    LD      r2, 0x0020              ; DST ID
;    OR      r1, r1, r2
;    ROL8    r1, r1
;    CALL    ed25519_point_generate
;    ST      r10, 0x1000 
;    ST      r11, 0x1020
;    ST      r12, 0x1040
;    END 
; ============================================================

invalid_op_id:
    MOVI    r0, ret_op_id_err
    ST      r0, ca_spect_res_word

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
    LSL     r0, r0
    LSL     r0, r0
    LSL     r0, r0
    LSL     r0, r0
    AND     r0, r0, r1
    RET
get_data_in_size:
    LD      r0, ca_spect_cfg_word
    ROR8    r0, r0
    ROR8    r0, r0
    MOVI    r1, 0xFF
    ROL8    r1, r1
    ORI     r1, r1, 0xFF
    AND     r0, r0, r1
    RET

; ============================================================
; Routine for setting  SPECT_RES_WORD field
; ============================================================
set_res_word:
    ST      r30, 0x1120
    ROL8    r1, r1
    ROL8    r1, r1
    ADD     r0, r0, r1
    ST      r0, ca_spect_res_word
    RET

;.include    field_math/inv_q256.s
;.include    field_math/inv_p256.s
.include    field_math/inv_p25519.s

.include    ecc_math/point_compress_ed25519.s
.include    ecc_math/point_decompress_ed25519.s
;.include    ecc_math/point_add_p256.s
;.include    ecc_math/point_dbl_p256.s
.include    ecc_math/point_add_ed25519.s
.include    ecc_math/point_dbl_ed25519.s
;.include    ecc_math/spm_p256.s
.include    ecc_math/spm_ed25519_short.s

;.include    ecc_point_generation/hash_to_field_p25519.s
;.include    ecc_point_generation/map_to_curve_elligator2_curve25519.s
;.include    ecc_point_generation/point_generate_curve25519.s
;.include    ecc_point_generation/point_generate_ed25519.s
;.include    ecc_point_generation/compose_exp_tag.s

;.include    ecc_crypto/ecdsa_key_setup.s
;.include    ecc_crypto/ecdsa_sign.s
;.include    ecc_crypto/x25519.s
.include    ecc_crypto/eddsa_verify.s

.include    ops/sha512_ops.s
.include    ops/ecc_key_ops.s
.include    ops/x25519_ops.s
.include    ops/eddsa_ops.s
.include    ops/ecdsa_ops.s
