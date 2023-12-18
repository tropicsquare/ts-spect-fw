; ==============================================================================
;  file    main.s
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
; Top source of Application Firmware
;
;   - ECC Key Ops
;   - X25519 Ops
;   - ECDSA Ops
;   - EdDSA Sequence
;
; ==============================================================================
; Constants Includes
; ==============================================================================
.include mem_layouts/mem_layouts_includes.s
.include constants/spect_ops_constants.s
.include constants/spect_descriptors_constants.s
.include constants/l3_result_const.s
.include constants/spect_ops_status.s
; ==============================================================================
; Op ID decoding 
; ==============================================================================
_start:
    LD      r0, ca_spect_cfg_word
    ADDI    r0, r0, 0                           ; force bits [255:32] to 0
    MOVI    r4, 0xFF
    AND     r1, r0, r4                          ; mask SPECT_OP_ID to r1[7:0]
    ANDI    r4, r1, 0xF0                        ; get only op type id

op_id_check_clear:
    CMPI    r1, clear_id
    BRZ     op_clear

op_id_check_ecc_key:
    CMPI    r4, ecc_key_id
    BRZ     op_ecc_key

op_id_check_x25519:
    CMPI    r4, x25519_id
    BRZ     op_x25519

op_id_check_eddsa:
    CMPI    r4, eddsa_id
    BRZ     op_eddsa

op_id_check_ecdsa:
    CMPI    r4, ecdsa_id
    BRZ     op_ecdsa

    JMP     invalid_op_id

; ==============================================================================
op_ecc_key:
    CMPI    r1, ecc_key_gen_id
    BRZ     op_ecc_key_gen_store

    CMPI    r1, ecc_key_store_id
    BRZ     op_ecc_key_gen_store

    CMPI    r1, ecc_key_read_id
    BRZ     op_ecc_key_read

    CMPI    r1, ecc_key_erase_id
    BRZ     op_ecc_key_erase

    JMP     invalid_op_id

; ==============================================================================
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

; ==============================================================================
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

    JMP     invalid_op_id

; ==============================================================================
op_ecdsa:
    CMPI    r1, ecdsa_sign_id
    BRZ     op_ecdsa_sign

    JMP     invalid_op_id
; ==============================================================================

invalid_op_id:
    MOVI    r2,  l3_result_invalid_cmd
    CALL    get_output_base
    STR     r2,  r0
    MOVI    r1,  0
    MOVI    r0,  ret_op_id_err
    JMP     set_res_word

; ==============================================================================
; Routines for geting fields from SPECT_CFG_WORD
; ==============================================================================
get_input_base:
    LD      r0,  ca_spect_cfg_word
    MOVI    r1,  0xF0
    ROL8    r1,  r1
    AND     r0,  r0,  r1
    RET
get_output_base:
    LD      r0,  ca_spect_cfg_word
    MOVI    r1,  0xF0
    ROL8    r1,  r1
    LSL     r0,  r0
    LSL     r0,  r0
    LSL     r0,  r0
    LSL     r0,  r0
    AND     r0,  r0,  r1
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

; ==============================================================================
; Routine for setting  SPECT_RES_WORD field
; ==============================================================================
set_res_word:
    ROL8    r1,  r1
    ROL8    r1,  r1
    ADD     r0,  r0,  r1
    ST      r0,  ca_spect_res_word
    END
; ==============================================================================

.include    routines_includes.s
