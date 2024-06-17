; ==============================================================================
;  file    ops/ecc_key_ops.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
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

ecc_key_get_k:
    CMPI    r1, ecc_key_gen_id
    BRZ     ecc_key_generate_k
    ADDI    r4,  r0,  ecc_key_store_input_k
    LDR     r19, r4
    RET

ecc_key_generate_k:
    GRV     r19
    RET

ecc_key_gen_ed25519_call:
    CALL    ecc_key_get_k
    CALL    ed25519_key_setup
    CMPI    r3,  0
    BRZ     ecc_key_gen_ed25519_call_ok
    MOVI    r2,  l3_result_fail
    JMP     op_key_setup_end

ecc_key_gen_ed25519_call_ok:
    MOVI    r2,  l3_result_ok
    JMP     op_key_setup_end

ecc_key_gen_p256_call:
    CALL    ecc_key_get_k
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
    MOVI    r1,  0
    STR     r2,  r0
    MOV     r0,  r3
    JMP     set_res_word


; ECC Key Read from slot
op_ecc_key_read:
    CALL    get_output_base
    MOV     r20, r0
    ADDI    r21, r20, ecc_key_output_result
    CALL    ecc_key_parse_input
    LSL     r25, r25
    ADDI    r25, r25, 1

    ; load kpair metadata
    LDK     r2,  r25, ecc_key_metadata
    BRE     op_key_fail

    ; mask curve
    MOVI    r30, 0xFF
    AND     r30, r30, r2

    MOVI    r26, 0

    ; load pubkey
    LDK     r16, r25, ecc_pub_key_Ax
    BRE     op_key_fail

    CMPI    r30,  ecc_type_p256
    BRNZ    ecc_key_read_skip_second_read

    ; load rest of p256 pubkey
    LDK     r17, r25, ecc_pub_key_Ay
    BRE     op_key_fail

ecc_key_read_skip_second_read:
    KBO     r25, ecc_kbus_flush
    BRE     op_key_fail

    ; compose return value
    ROL8    r2,  r2
    ORI     r2,  r2,  l3_result_ok
    MOVI    r0,  0
    JMP     op_key_read_end

op_key_fail:
    MOVI    r2,  l3_result_fail
    STR     r2,  r21
    MOVI    r1,  1
    KBO     r25, ecc_kbus_flush
    MOVI    r0,  ret_key_err
    JMP     set_res_word

op_key_read_end:
    STR     r2,  r21
    ADDI    r22, r20, ecc_key_read_output_pub_key
    SWE     r16, r16
    STR     r16, r22
    ADDI    r22, r22, 0x20
    SWE     r17, r17
    STR     r17, r22
    MOVI    r1,  48
    MOVI    r0,  ret_op_success
    JMP     set_res_word

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
    LDK     r2,  r25, ecc_key_metadata
    BRE     op_key_fail
    KBO     r25, ecc_kbus_erase
    BRE     op_key_fail
    KBO     r25, ecc_kbus_verify_erase
    BRE     op_key_fail
    KBO     r25, ecc_kbus_flush

    ROL8    r2,  r2
    ORI     r2,  r2,  l3_result_ok

    STR     r2,  r21

    MOVI    r1,  3
    MOVI    r0,  ret_op_success
    JMP     set_res_word
