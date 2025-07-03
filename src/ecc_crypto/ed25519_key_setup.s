; ==============================================================================
;  file    ecc_crypto/ed25519_key_setup.s
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
; Key setup for curve Ed25519 (EdDSA)
;
; Algorithm:
;   1) H = SHA512(k)
;   2) H[0,1,2,255] = 0 and H[254] = 1
;   3) s = H[255:0]
;   4) prefix = H[511:256]
;   5) A = ENC(s.G)
;
; Inputs:
;   seed k in r19
;   physical priv key slot in r25
;   physical pub key slot in r26
;
; Outputs:
;   Writes the key set (s, prefix, s mod q, A) to ECC key slot via KBUS
;   spect status in r3
;
; Masking methods:
;   1) Randomized Coordinates       -- (x, y, z, t) == (rx, ry, rz, rt)
;   2) Group Scalar Randomization   -- k' = k + r * #E
;
; See doc/ecc_key_layout.md for placement of the key values into physical slots.
;
; ==============================================================================

ed25519_key_setup:
    CMPI        r1, ecc_key_gen_id
    BRZ         ed25519_key_setup_generate_k
    ADDI        r4,  r0,  ecc_key_store_input_k
    LDR         r19, r4
    JMP         ed25519_key_setup_start

ed25519_key_setup_generate_k:
    GRV         r19
ed25519_key_setup_start:
    ; Add padding to k
    MOVI        r18, 1
    ROR         r18, r18
    MOVI        r17, 0
    MOVI        r16, 256
    SWE         r19, r19

    ; H = SHA512(k)
    HASH_IT
    HASH        r28, r16

    ; Derive s from H[255:0] to become secret scalar
    SWE         r29, r29
    MOVI        r0,  7
    MOVI        r1,  255
    SBIT        r0,  r0, r1
    NOT         r0,  r0
    AND         r29, r0, r29
    MOVI        r1,  254
    SBIT        r29, r29, r1

    ; Derive prefix from H[511:256] as little-endian integer
    SWE         r28, r28

    ST          r29, ca_ed25519_key_setup_internal_s
    ST          r28, ca_ed25519_key_setup_internal_prefix
    GRV         r30
    LD          r31, ca_q25519
    SCB         r28, r29, r30

    ; Load base point G, mask it and check its validity
    LD          r31, ca_p25519
    LD          r11, ca_ed25519_xG
    LD          r12, ca_ed25519_yG

    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field

    ORI         r13, r0,  1         ; Ensure that Z != 0
    MUL25519    r11, r11, r13       ; X = x * Z
    MUL25519    r14, r11, r12       ; T = x * y * Z = X * y
    MUL25519    r12, r12, r13       ; Y = y * Z

    LD          r6,  ca_ed25519_d

    MOV         r7,  r11
    MOV         r8,  r12
    MOV         r9,  r13
    MOV         r10, r14

    CALL        point_check_ed25519
    BRNZ        ed25519_key_setup_spm_fail

    ; Calculate A = s.G and check validity of the result
    CALL        spm_ed25519_long
    CALL        point_check_ed25519
    BRNZ        ed25519_key_setup_spm_fail

    ; Transform A back to affine coordinates
    CALL        point_compress_ed25519

    ; Compose kpair metadata
    ROR         r10, r25                        ; User slot
    ROL8        r10, r10
    ORI         r10, r10, ecc_pub_slot_id       ; Add public slot id
    ROL8        r10, r10
    LD          r0,  ca_spect_cfg_word
    MOVI        r4,  0xFF
    AND         r9,  r0,  r4                    ; mask SPECT_OP_ID to r9[7:0]
    CMPI        r9,  ecc_key_gen_l3_cmd_id
    BRZ         ed25519_key_setup_origin_gen
ed25519_key_setup_origin_st:
    ORI         r10, r10, ecc_key_origin_st
    JMP         ed25519_key_setup_origin_continue
ed25519_key_setup_origin_gen:
    ORI         r10, r10, ecc_key_origin_gen

ed25519_key_setup_origin_continue:
    ROL8        r10, r10
    ORI         r10, r10, ecc_type_ed25519

    STK         r10, r26, ecc_key_metadata      ; store metadata
    BRE         ed25519_key_setup_kbus_fail

    ; Store the pubkey to key slot
    STK         r8,  r26, ecc_pub_key_Ax        ; store A
    BRE         ed25519_key_setup_kbus_fail

    KBO         r26, ecc_kbus_program           ; program
    BRE         ed25519_key_setup_kbus_fail
    KBO         r26, ecc_kbus_flush             ; flush
    BRE         ed25519_key_setup_kbus_fail

    ; Store s and prefix to key slot
    LD          r28, ca_ed25519_key_setup_internal_s
    LD          r29, ca_ed25519_key_setup_internal_prefix
    MOVI        r0,  0
    LD          r31, ca_q25519
    REDP        r30, r0,  r28

    ; Split the scalar
    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field

    ; Ensure s2 != 0
    ORI         r0,  r0,  1
    SUBP        r28, r30, r0
    ; Mask prefix
    GRV         r2
    XOR         r29, r29, r2

    ; Change slot - needed so the slot register is same for flush in case of error
    MOV         r26, r25

    ; make private slot metadata
    MOVI        r9,  0xFF
    ROL8        r9,  r9
    ROL8        r9,  r9
    XOR         r10, r10, r9

    STK         r28, r26, ecc_priv_key_1        ; store s1
    BRE         ed25519_key_setup_kbus_fail
    STK         r29, r26, ecc_priv_key_2        ; store prefix
    BRE         ed25519_key_setup_kbus_fail
    STK         r0,  r26, ecc_priv_key_3        ; store s2
    BRE         ed25519_key_setup_kbus_fail
    STK         r2,  r26, ecc_priv_key_4        ; prefix mask
    BRE         ed25519_key_setup_kbus_fail
    STK         r10, r26, ecc_key_metadata      ; priv metadata
    BRE         ed25519_key_setup_kbus_fail
    KBO         r26, ecc_kbus_program           ; program
    BRE         ed25519_key_setup_kbus_fail
    KBO         r26, ecc_kbus_flush             ; flush
    BRE         ed25519_key_setup_kbus_fail

    ; Return success
    MOVI        r3,  0
    RET

ed25519_key_setup_spm_fail:
    KBO         r26, ecc_kbus_flush
    MOVI        r3,  ret_point_integrity_err
    RET

ed25519_key_setup_kbus_fail:
    KBO         r26, ecc_kbus_flush
    MOVI        r3,  ret_key_err
    RET