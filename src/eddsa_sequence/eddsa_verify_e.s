; ==============================================================================
;  file    eddsa_sequence/eddsa_verify_e.s
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
; Verify EdDSA signature with precomputed E = SHA512(R, A, M) mod q
;
; Inputs:
;   E in r25
;   signature part S in ca_eddsa_sign_internal_S
;   signature part R in ca_eddsa_sign_internal_R
;   public key A in ca_eddsa_sign_internal_A
;
; Outputs:
;   Verification result in r30
;       verified : pass_val
;
; ==============================================================================
eddsa_verify_e_pass:
    MOVI        r30,  pass_val
    RET

eddsa_verify_e:
    ; Store call check
    MOVI        r0,  call_check_level_1_id
    ST          r0,  ca_call_check_level_1
    ; Check E != 0
    MOVI        r0, 0
    XOR         r1, r0, r25
    BRZ         eddsa_verify_e_fail

    ; r29 <- S
    LD          r29, ca_eddsa_sign_internal_S

    ; Check S != 0
    XOR         r1, r0, r29
    BRZ         eddsa_verify_e_fail

    ; decompress public key to extended coordinates
    ; (r11, r12, r13, r14) <-- A
    LD          r31, ca_p25519
    LD          r6,  ca_ed25519_d
    LD          r12, ca_eddsa_sign_internal_A
    SWE         r12, r12
    CALL        point_decompress_ed25519

    ; Check decompress success
    CMPI        r31, 0      ; CLEAR zero flag
    CMPI        r1,  pass_val
    BRNZ        eddsa_finish_fail_invalid_pubkey

; ==============================================================================
;   Compute Q = [-E].A + [S].G using DSPM
; ==============================================================================
    ; r28 <- -E
    LD          r31, ca_q25519
    MOVI        r0,  0
    SUBP        r28, r0,  r25
    LD          r31, ca_p25519

    ; Randomize public point A
    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field
    ORI         r13, r0,  1                     ; Ensure that Z != 0
    MUL25519    r11, r11, r13                   ; X = x * Z
    MUL25519    r14, r11, r12                   ; T = x * y * Z = X * y
    MUL25519    r12, r12, r13                   ; Y = y * Z

    ; Load and randomize Ed25519 G point
    LD          r15, ca_ed25519_xG
    LD          r16, ca_ed25519_yG

    GRV         r2
    LD          r1, ca_gfp_gen_dst
    CALL        hash_to_field
    ORI         r17, r0,  1                     ; Ensure that Z != 0
    MUL25519    r15, r15, r17                   ; X = x * Z
    MUL25519    r18, r15, r16                   ; T = x * y * Z = X * y
    MUL25519    r16, r16, r17                   ; Y = y * Z

    ; (r7, r8, r9, r10) <- Q = [-E].A + [S].G
    CALL        spm_ed25519_double
    CMPI        r0,  pass_val
    BRNZ        eddsa_verify_e_fail

    ; check Q != O
    CALL        point_check_infinity_ed25519
    BRZ         eddsa_verify_e_fail

    ; r8 <- ENC(Q)
    CALL        point_compress_ed25519

    ; r4 <- ENC(R)
    LD          r5,  ca_eddsa_sign_internal_R

    ; Check ENC(Q) == ENC(R)
    CMPI        r31, 0     ; Clear zero flag
    XOR         r2,  r8,  r5
    BRZ         eddsa_verify_e_pass

eddsa_verify_e_fail:
    MOVI        r30, fail_val
    RET
