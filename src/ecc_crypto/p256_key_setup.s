; ==============================================================================
;  file    ecc_crypto/p256_key_setup.s
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
; Key setup for curve NIST P-256 (ECDSA)
;
; Algorithm:
;   1) d = k mod q, if d == 0: fail
;   2) w = TMAC(d, "", 0xA)
;   3) A = d.G
;
; Input:
;   input src in r0
;   generate / store command in r1
;   physical priv key slot in r25
;   physical pub key slot in r26
;
; Outputs:
;   Populates the ECC key slot (private + public) with new ECDSA key pair.
;   spect status in r3
;
; Masking methods:
;   1) Random Projective Coordinates -- (x, y, z) == (rx, ry, rz)
;   2) Group Scalar Randomization -- k' = k + r * #E
;
; See doc/ecc_key_layout.md for placement of the key values into physical slots.
;
; ==============================================================================

p256_key_setup:
    LD      r31, ca_q256

    ; Decide if generate randomly, or if 'k' is provided by the user
    CMPI    r1, ecc_key_gen_id
    BRZ     p256_key_setup_generate_k

    ; Load and check 'k' provided by the user
    ADDI    r4,  r0,  ecc_key_store_input_k
    LDR     r19, r4
    SWE     r19, r19
    MOVI    r20,  0
    REDP    r28, r20, r19

    XOR     r1,  r28, r19
    BRNZ    p256_key_setup_fail
    XORI    r1,  r28, 0
    BRZ     p256_key_setup_fail
    JMP     p256_key_setup_start

    ; Generate random 'k'
p256_key_setup_generate_k:
    GRV     r19
    GRV     r20
    REDP    r28, r20, r19

    XORI    r1,  r28, 0
    BRZ     p256_key_setup_fail

; ==============================================================================
;   Compute w = TMAC(d, "", 0xA)
; ==============================================================================
p256_key_setup_start:
    GRV     r0
    GRV     r1
    GRV     r2
    GRV     r3

    TMAC_IT r0
    TMAC_IS r28, tmac_dst_ecdsa_key_setup

    MOVI    r2,  0x04
    MOVI    r30, 17

    ; TMAC padding of an empty string
p256_key_setup_tmac_padding_loop:
    ROL8    r2,  r2
    SUBI    r30, r30, 1
    BRNZ    p256_key_setup_tmac_padding_loop
    ORI     r2, r2, 0x80

    TMAC_UP r2
    TMAC_RD r29

    ST      r28, ca_p256_key_setup_internal_d
    ST      r29, ca_p256_key_setup_internal_w

; ==============================================================================
;   Compute A = d.G
; ==============================================================================
    LD      r31, ca_q256

    ; Mask the scalar
    GRV     r30
    SCB     r28, r28, r30

    LD      r31, ca_p256

    ; Load the ECDSA base point
    LD      r12, ca_p256_xG
    LD      r13, ca_p256_yG

    MOVI    r14, 1

    ; Randomize the base points Z-coordinate
    GRV     r2
    LD      r1, ca_gfp_gen_dst
    CALL    hash_to_field

    ORI     r14, r0,  1         ; Ensure that Z != 0
    MUL256  r12, r12, r14
    MUL256  r13, r13, r14

    MOV     r9,  r12
    MOV     r10, r13
    MOV     r11, r14

    CALL    point_check_p256
    BRNZ    p256_key_setup_spm_fail

    ; Compute the scalar point multiple
    LD      r8,  ca_p256_b

    CALL    spm_p256_long
    CMPI    r0,  0
    BRNZ    p256_key_setup_spm_fail
    CALL    point_check_p256
    BRNZ    p256_key_setup_spm_fail

    ; Convert the result to affine coordinates
    MOV     r1, r11
    CALL    inv_p256
    MUL256  r9, r9, r1
    MUL256  r10, r10, r1

; ==============================================================================
;   Write the keys to the slot
; ==============================================================================

    ; Compose key pair metadata
    ROR     r12, r25                            ; User slot
    ROL8    r12, r12
    ORI     r12, r12, ecc_pub_slot_id           ; Add public slot id
    ROL8    r12, r12
    LD      r0,  ca_spect_cfg_word
    MOVI    r4,  0xFF
    AND     r20, r0,  r4                        ; mask SPECT_OP_ID to r20[7:0]
    CMPI    r20, ecc_key_gen_l3_cmd_id
    BRZ     p256_key_setup_origin_gen
p256_key_setup_origin_st:
    ORI     r12, r12, ecc_key_origin_st
    JMP     p256_key_setup_origin_continue
p256_key_setup_origin_gen:
    ORI     r12, r12, ecc_key_origin_gen

p256_key_setup_origin_continue:
    ROL8    r12, r12
    ORI     r12, r12, ecc_type_p256
    STK     r12, r26, ecc_key_metadata          ; store metadata
    BRE     p256_key_setup_fail

    ; Populate the public slot with the pubkey
    STK     r9,  r26, ecc_pub_key_Ax            ; store Ax
    BRE     p256_key_setup_fail
    STK     r10, r26, ecc_pub_key_Ay            ; store Ay
    BRE     p256_key_setup_fail
    KBO     r26, ecc_kbus_program               ; program
    BRE     p256_key_setup_fail
    KBO     r26, ecc_kbus_flush                 ; flush
    BRE     p256_key_setup_fail

    LD      r28, ca_p256_key_setup_internal_d
    LD      r29, ca_p256_key_setup_internal_w

    ; split priv key d
    LD      r31, ca_q256
    GRV     r2
    LD      r1, ca_gfp_gen_dst
    CALL    hash_to_field
    SUBP    r28, r28, r0

    ; mask priv key w
    GRV     r2
    XOR     r29, r29, r2

    ; Change slot - needed so the slot register is same for flush in case of error
    MOV     r26, r25

    ; make private slot metadata
    MOVI    r9,  0xFF
    ROL8    r9,  r9
    ROL8    r9,  r9
    XOR     r10, r12, r9

    ; Populate the private slot with priv keys and masks
    STK     r28, r26, ecc_priv_key_1            ; store d1
    BRE     p256_key_setup_fail
    STK     r29, r26, ecc_priv_key_2            ; store w
    BRE     p256_key_setup_fail
    STK     r0,  r26, ecc_priv_key_3            ; store d2
    BRE     p256_key_setup_fail
    STK     r2,  r26, ecc_priv_key_4            ; store w mask
    BRE     p256_key_setup_fail
    STK     r10, r26, ecc_key_metadata          ; priv metadata
    BRE     p256_key_setup_fail
    KBO     r26, ecc_kbus_program               ; program
    BRE     p256_key_setup_fail
    KBO     r26, ecc_kbus_flush                 ; flush
    BRE     p256_key_setup_fail

    ; Return success
    MOVI    r3, ret_op_success
    RET

p256_key_setup_fail:
    KBO     r26, ecc_kbus_flush
    MOVI    r3,  ret_key_err
    RET

p256_key_setup_spm_fail:
    KBO     r26, ecc_kbus_flush
    MOVI    r3,  ret_point_integrity_err
    RET