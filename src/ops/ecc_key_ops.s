; ==============================================================================
;  file    ops/ecc_key_ops.s
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
; ECC Key Ops:
;   - ECC Key Generate
;   - ECC Key Store
;   - ECC Key Read
;   - ECC Key Erase
;
; ==============================================================================

ecc_key_parse_input:
    CALL    get_input_base
    ADDI    r4,  r0,  ecc_key_input_cmd_in
    LDR     r4,  r4
    MOVI    r2,  0xFF
    AND     r1,  r4,  r2
    ROR8    r25, r4
    ROR8    r4,  r25
    ROR8    r4,  r4
    AND     r25, r25, r2                    ; SLOT
    AND     r4,  r4,  r2                    ; CURVE
    RET

; ECC Key Generate/Store
op_ecc_key_gen_store:
    CALL    ecc_key_parse_input
    LSL     r25, r25                        ; physical priv key slot

    ; check if priv key slot is empty
    KBO     r25, ecc_kbus_verify_erase
    BRE     op_key_fail

    ADDI    r26, r25, 1                     ; physical pub key slot

    ; check if pub key slot is empty
    KBO     r26, ecc_kbus_verify_erase
    BRE     op_key_fail

    CMPI    r4,  ecc_type_ed25519
    BRZ     ecc_key_gen_ed25519_call
    CMPI    r4,  ecc_type_p256
    BRZ     ecc_key_gen_p256_call

    MOVI    r3, ret_curve_type_err
    MOVI    r2, l3_result_fail
    JMP     op_key_setup_end

ecc_key_gen_ed25519_call:
    ;CALL    ecc_key_get_k
    CALL    ed25519_key_setup
    CMPI    r3,  0
    BRZ     ecc_key_gen_ed25519_call_ok
    MOVI    r2,  l3_result_fail
    JMP     op_key_setup_end

ecc_key_gen_ed25519_call_ok:
    MOVI    r2,  l3_result_ok
    JMP     op_key_setup_end

ecc_key_gen_p256_call:
    ;CALL    ecc_key_get_k
    CALL    p256_key_setup
    CMPI    r3,  0
    BRZ     ecc_key_gen_p256_call_ok
    MOVI    r2,  l3_result_fail
    JMP     op_key_setup_end

ecc_key_gen_p256_call_ok:
    MOVI    r2,  l3_result_ok
    JMP     op_key_setup_end

op_key_setup_end:
    CALL    get_output_base
    ADDI    r0,  r0,  ecc_key_output_result
    MOVI    r1,  1
    STR     r2,  r0
    MOV     r0,  r3
    JMP     op_ecc_key_clean

; ECC Key Read from slot
op_ecc_key_read:
    CALL    get_output_base
    MOV     r20, r0
    ADDI    r21, r20, ecc_key_output_result
    CALL    ecc_key_parse_input
    LSL     r26, r25
    ADDI    r26, r26, 1

    MOVI    r3,  ret_key_err
    KBO     r26, ecc_kbus_verify_erase
    BRNE    op_key_read_invalid

    ; load kpair metadata
    LDK     r16,  r26, ecc_key_metadata
    BRE     op_key_fail

    ; check metadata
    MOVI    r3,  ret_slot_metadata_err
    MOVI    r30, 0xFF
    MOV     r5,  r16

    ; 'Origin'
    ROR8    r5,  r5
    AND     r4,  r5,  r30
    CMPI    r4,  ecc_key_origin_gen
    BRZ     ecc_key_read_check_slot_type
    CMPI    r4,  ecc_key_origin_st
    BRNZ    op_key_read_invalid

    ; 'Slot Type'
ecc_key_read_check_slot_type:
    ROR8    r5,  r5
    AND     r4,  r5,  r30
    CMPI    r4,  ecc_pub_slot_id
    BRNZ    op_key_read_invalid

    ; 'Slot Number'
    ROR8    r5,  r5
    AND     r4,  r5,  r30
    CMP     r4,  r25
    BRNZ    op_key_read_invalid

    ; mask curve
    MOVI    r3,  ret_curve_type_err
    AND     r30, r30, r16

    CMPI    r30, ecc_type_ed25519
    BRZ     ecc_key_read_ed25519

    CMPI    r30,  ecc_type_p256
    BRNZ    op_key_read_invalid

ecc_key_read_p256:
    ; Check that the ECC pub is valid P-256 Pub
    MOV     r9,  r7
    MOV     r10, r8
    MOVI    r11, 1
    LD      r31, ca_p256
    CALL    point_check_p256
    MOVI    r3,  ret_key_err
    BRNZ    op_key_read_invalid

    MOVI    r1,  80     ; No compression
    JMP     ecc_key_read_continue
ecc_key_read_ed25519:
    ; Check that the ECC pub is valid Ed25519 Pub
    LD          r31, ca_p25519
    LD          r6,  ca_ed25519_d
    MOVI        r9,  1  ; Z
    MUL25519    r10, r7,  r8
    CALL        point_valid_check_ed25519
    MOVI        r3,  ret_key_err
    BRNZ        op_key_read_invalid

    ; Compress to r7 for output
    CALL    point_compress_ed25519_from_affine
    MOV     r7,  r8
    MOVI    r8,  0

    MOVI    r1,  48

ecc_key_read_continue:
    KBO     r26, ecc_kbus_flush
    BRE     op_key_fail

    ; compose return value
    MOVI    r5,  0xFFF
    AND     r2,  r16, r5
    ROL8    r2,  r2
    ORI     r2,  r2,  l3_result_ok
    MOVI    r0,  0
    JMP     op_key_read_end

op_key_read_invalid:
    MOVI    r2,  l3_result_invalid_key
    KBO     r26, ecc_kbus_flush
    JMP     op_key_setup_end

op_key_fail:
    MOVI    r2,  l3_result_fail
    MOVI    r3,  ret_key_err
    KBO     r26, ecc_kbus_flush
    JMP     op_key_setup_end

op_key_read_end:
    STR     r2,  r21
    ADDI    r22, r20, ecc_key_read_output_pub_key
    SWE     r16, r16
    STR     r16, r22
    ADDI    r22, r22, 0x20
    SWE     r17, r17
    STR     r17, r22
    MOVI    r0,  ret_op_success
    JMP     op_ecc_key_clean

; ECC Key Erase from slot
op_ecc_key_erase:
    CALL    ecc_key_parse_input
    LSL     r25, r25

    CALL    get_output_base
    ADDI    r21, r0,  ecc_key_output_result

    ; Erase priv key slot
    KBO     r25, ecc_kbus_erase
    BRE     op_key_fail
    KBO     r25, ecc_kbus_verify_erase
    BRE     op_key_fail
    KBO     r25, ecc_kbus_flush

    ADDI    r25, r25, 1

    ; Erase pub key slot
    KBO     r25, ecc_kbus_erase
    BRE     op_key_fail
    KBO     r25, ecc_kbus_verify_erase
    BRE     op_key_fail
    KBO     r25, ecc_kbus_flush

    MOVI    r2,  l3_result_ok
    STR     r2,  r21

    MOVI    r1,  1
    MOVI    r0,  ret_op_success
    JMP     op_ecc_key_clean

op_ecc_key_clean:
    MOVI    r31, 0
    CALL    clear_data_in
    CALL    clear_regs_before_return
    JMP     set_res_word
