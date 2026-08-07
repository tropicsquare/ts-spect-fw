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
    ; r25 <- SLOT
    ; r4  <- CURVE
    CALL        get_input_base
    ADDI        r4,  r0,  ecc_key_input_cmd_in
    LDR         r4,  r4
    MOVI        r2,  0xFF
    AND         r1,  r4,  r2                            ; CMD_ID
    ROR8        r25, r4
    ROR8        r4,  r25
    ROR8        r4,  r4
    AND         r25, r25, r2                            ; SLOT
    AND         r4,  r4,  r2                            ; CURVE
    RET

; ==============================================================================
; ECC_Key_Generate + ECC_Key_Store
; ==============================================================================
op_ecc_key_gen_store:
    CALL        ecc_key_parse_input

    LSL         r25, r25                                ; r25 <- physical priv key slot
    ADDI        r26, r25, 1                             ; r26 <- physical pub key slot

    ; Check that priv key slot is empty
    KBO         r25, ecc_kbus_verify_erase
    BRE         op_key_fail

    ; Check that pub key slot is empty
    KBO         r26, ecc_kbus_verify_erase
    BRE         op_key_fail

    ; Branch based on CURVE field
    CMPI        r4,  ecc_type_ed25519
    BRZ         ecc_key_gen_ed25519_call
    CMPI        r4,  ecc_type_p256
    BRZ         ecc_key_gen_p256_call

    ; If here, the CURVE field has invalid value
    MOVI        r3, ret_curve_type_err
    MOVI        r2, l3_result_fail
    JMP         op_key_setup_end

; === ED25519 Key Setup ========================================================
ecc_key_gen_ed25519_call:
    CALL        ed25519_key_setup
    CMPI        r3,  0
    BRZ         ecc_key_gen_ed25519_call_ok
    MOVI        r2,  l3_result_fail
    JMP         op_key_setup_end

ecc_key_gen_ed25519_call_ok:
    MOVI        r2,  l3_result_ok
    JMP         op_key_setup_end

; === P-256 Key Setup ==========================================================
ecc_key_gen_p256_call:
    CALL        p256_key_setup
    CMPI        r3,  0
    BRZ         ecc_key_gen_p256_call_ok
    MOVI        r2,  l3_result_fail
    JMP         op_key_setup_end

ecc_key_gen_p256_call_ok:
    MOVI        r2,  l3_result_ok
    JMP         op_key_setup_end

; === End of Key Setup =========================================================
op_key_setup_end:
    CALL        get_output_base
    ADDI        r0,  r0,  ecc_key_output_result
    MOVI        r1,  1
    STR         r2,  r0
    MOV         r0,  r3
    JMP         op_ecc_key_clean

; ==============================================================================
; ECC_Key_Read
; ==============================================================================
op_ecc_key_read:
    CALL        ecc_key_parse_input
    LSL         r26, r25
    ADDI        r26, r26, 1                             ; r26 <- physical pub key slot

    MOVI        r3,  ret_key_err
    KBO         r26, ecc_kbus_verify_erase
    BRNE        op_key_read_invalid

    ; Load SLOT Metadata
    LDK         r15,  r26, ecc_key_metadata
    BRE         op_key_fail

; === Parse and check SLOT Metadata ============================================
; We keep the metadata word in r15 because it is part of the response data
    MOVI        r3,  ret_slot_metadata_err
    MOVI        r30, 0xFF
    MOV         r5,  r15

    ; Check Origin
    ROR8        r5,  r5
    AND         r4,  r5,  r30
    CMPI        r4,  ecc_key_origin_gen
    BRZ         ecc_key_read_check_slot_type
    CMPI        r4,  ecc_key_origin_st
    BRNZ        op_key_read_invalid

ecc_key_read_check_slot_type:
    ; Check Slot Type (it shall be 'Pub')
    ROR8        r5,  r5
    AND         r4,  r5,  r30
    CMPI        r4,  ecc_pub_slot_id
    BRNZ        op_key_read_invalid

    ; Check Slot Number (it shall be equal to the SLOT field of the L3 CMD in r25)
    ROR8        r5,  r5
    AND         r4,  r5,  r30
    CMP         r4,  r25
    BRNZ        op_key_read_invalid

; === Read the public key ======================================================
    ; Get Curve Type from Slot Metadata
    MOVI        r3,  ret_curve_type_err
    AND         r30, r30, r15

    ; Branch based on the Curve Type
    CMPI        r30, ecc_type_ed25519
    BRZ         ecc_key_read_ed25519

    CMPI        r30,  ecc_type_p256
    BRNZ        op_key_read_invalid                 ; Invalid Curve Type

; === Check and prepare P-256 Public key =======================================
ecc_key_read_p256:
    ; (r7, r8) <- A
    LDK         r7,  r26, ecc_pub_key_Ax
    BRE         op_key_fail
    LDK         r8,  r26, ecc_pub_key_Ay
    BRE         op_key_fail
    ; Check that A is valid P-256 Pub
    LD          r31, ca_p256
    MOV         r9,  r7                             ; r9  <- Ax
    MOV         r10, r8                             ; r10 <- Ay
    MOVI        r11, 1                              ; r11 <- Az = 1
    CALL        point_check_p256
    MOVI        r3,  ret_key_err
    BRNZ        op_key_read_invalid

    MOVI        r1,  80                             ; r1 <- response data size (16+64 B)
    JMP         ecc_key_read_continue

; === Check and prepare Ed25519 Public key =====================================
ecc_key_read_ed25519:
    ; Ed25519 Public key is stored compressed
    ; Compressed public key pass the point validity check in ~50 % cases
    ; Therefore we read the compressed value twice and compare
    LDK         r7,  r26, ecc_pub_key_Ax
    BRE         op_key_fail
    LDK         r12, r26, ecc_pub_key_Ax
    BRE         op_key_fail

    MOVI        r3,  ret_key_err
    XOR         r8,  r12,  r7
    BRNZ        op_key_read_invalid

    LD          r31, ca_p25519
    LD          r6,  ca_ed25519_d
    SWE         r12, r12
    CALL        point_decompress_ed25519
    MOVI        r3,  ret_key_err
    CMPI        r1,  pass_val
    BRNZ        op_key_read_invalid

    MOVI        r8,  0
    MOVI        r1,  48                             ; r1 <- response data size (16+32 B)

; === Finalize ECC_Key_Read ====================================================
ecc_key_read_continue:
    KBO         r26, ecc_kbus_flush
    BRE         op_key_fail

    ; Compose return value (ORIGIN | CURVE | L3 Result)
    MOVI        r5,  0xFFF
    AND         r2,  r15, r5
    ROL8        r2,  r2
    ORI         r2,  r2,  l3_result_ok
    MOVI        r0,  0

    ; Store the L3 Response
    CALL        get_output_base

    STR         r2,  r0                             ; L3 Result + Metadata
    ADDI        r0,  r0,  ecc_key_read_output_pub_key
    SWE         r7,  r7
    STR         r7,  r0                             ; First 32B of the Public key
    ADDI        r0,  r0,  0x20
    SWE         r8,  r8
    STR         r8,  r0                             ; Second 32B of the Public key (0s for Ed25519)

    MOVI        r0,  ret_op_success
    JMP         op_ecc_key_clean

op_key_read_invalid:
    MOVI        r2,  l3_result_invalid_key
    KBO         r26, ecc_kbus_flush
    JMP         op_key_setup_end

op_key_fail:
    MOVI        r2,  l3_result_fail
    MOVI        r3,  ret_key_err
    KBO         r26, ecc_kbus_flush
    JMP         op_key_setup_end

; ==============================================================================
; ECC_Key_Erase
; ==============================================================================
op_ecc_key_erase:
    CALL        ecc_key_parse_input

; === Erase Private Slot =======================================================
    LSL         r26, r25                            ; r26 <- physical priv key slot

    KBO         r26, ecc_kbus_erase
    BRE         op_key_fail
    KBO         r26, ecc_kbus_verify_erase
    BRE         op_key_fail
    KBO         r26, ecc_kbus_flush

; === Erase Public Slot ========================================================
    ADDI        r26, r26, 1                         ; r26 <- physical pub key slot

    KBO         r26, ecc_kbus_erase
    BRE         op_key_fail
    KBO         r26, ecc_kbus_verify_erase
    BRE         op_key_fail
    KBO         r26, ecc_kbus_flush

; === Store L3 Response ========================================================
    CALL        get_output_base
    MOVI        r2,  l3_result_ok
    STR         r2,  r0

    MOVI        r1,  1
    MOVI        r0,  ret_op_success
    JMP         op_ecc_key_clean

op_ecc_key_clean:
    MOVI        r31, 0
    CALL        clear_data_in
    CALL        clear_regs_before_return
    JMP         set_res_word
