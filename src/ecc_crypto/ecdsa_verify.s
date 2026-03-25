; ==============================================================================
;  file    ecc_crypto/ecdsa_verify.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright (c) 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; ECDSA Verify over P-256
;
; Inputs:
;   Public key:
;       X : ca_ecdsa_sign_internal_Ax
;       Y : ca_ecdsa_sign_internal_Ay
;
;   Signature in:
;       r : ca_ecdsa_sign_internal_r
;       s : ca_ecdsa_sign_internal_s
;
;   Message Digest:
;       z : ca_ecdsa_sign_internal_z
;
; Outputs:
;   Verification result in r30
;       verified : pass_val
;
; ==============================================================================

ecdsa_verify_pass:
    MOVI        r30, pass_val
    RET

ecdsa_verify_call_check:
    ; Store call check
    MOVI        r0,  call_check_level_1_id
    ST          r0,  ca_call_check_level_1
ecdsa_verify:
    ; r1 <- s
    LD          r1,  ca_ecdsa_sign_internal_s
    ; r19 <- r
    LD          r19, ca_ecdsa_sign_internal_r
    ; r18 <- z
    LD          r18, ca_ecdsa_sign_internal_z

    MOVI        r0,  0
    XOR         r2,  r0,  r1                    ; Check that s != 0
    BRZ         ecdsa_verify_fail
    XOR         r3,  r0,  r19                   ; Check that r != 0
    BRZ         ecdsa_verify_fail

; ==============================================================================
;   Compute:
;       u1 = z/s
;       u2 = r/s
; ==============================================================================
    LD          r31, ca_q256
    CALL        inv_q256

    ; r28 <- u1
    MULP        r28, r18, r1
    ; r29 <- u2
    MULP        r29, r19, r1

; ==============================================================================
;   Compute: [u1.G + u2.A]x
; ==============================================================================
    LD          r31, ca_p256
    LD          r8,  ca_p256_b

    ; Load and randomize P-256 G point
    LD          r12, ca_p256_xG
    LD          r13, ca_p256_yG
    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field
    ORI         r14, r0,  1                     ; Ensure that Z != 0
    MUL256      r12, r12, r14
    MUL256      r13, r13, r14

    ; Load and randomize public point A
    LD          r15, ca_ecdsa_sign_internal_Ax
    LD          r16, ca_ecdsa_sign_internal_Ay
    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field
    ORI         r17, r0,  1                     ; Ensure that Z != 0
    MUL256      r15, r15, r17
    MUL256      r16, r16, r17

    ; Call double scalar point multiplication subroutine
    CALL        spm_p256_double
    CMPI        r0,  pass_val
    BRNZ        ecdsa_verify_fail

    ; Convert the Qx to affine coordinates
    MOV         r1,  r11
    ; r1 <- Qz^(-1)
    CALL        inv_p256
    ; r0 <- Qx (affine)
    MUL256      r0,  r9,  r1

; ==============================================================================
;   Check: [u1.G + u2.A]x == r
; ==============================================================================
    XOR         r0,  r0,  r19
    BRZ         ecdsa_verify_pass

ecdsa_verify_fail:
    MOVI        r30, fail_val
    RET
