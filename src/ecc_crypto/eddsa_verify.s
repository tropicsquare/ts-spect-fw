; ==============================================================================
;  file    ecc_crypto/eddsa_verify.s
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
; Routine for EdDSA signature verification for boot-up firmware.
; Only 64 byte message is supported
;
; Inputs:
;   Signature (R,S) : 0x0020-0x005F
;   Public key      : 0x0060-0x007F
;   Message         : 0x0080-0x009F
;
; Outputs:
;   Result 1 : 0x0 (0x0B5E55ED => verified)
;   Result 2 : 0x4 (0xBA11FADE => verified)
;
; ==============================================================================

eddsa_verify:
    ; load and set needed parameters
    LD          r28, eddsa_verify_input_S
    LD          r31, ca_p25519
    LD          r6,  ca_ed25519_d
    LD          r11, ca_ed25519_xG
    LD          r12, ca_ed25519_yG
    MOVI        r13, 1
    MUL25519    r14, r11, r12

; ==============================================================================
;   Q1 = S.B
; ==============================================================================

    CALL        spm_ed25519_short
    ST          r7,  ca_eddsa_verify_internal_SBx
    ST          r8,  ca_eddsa_verify_internal_SBy
    ST          r9,  ca_eddsa_verify_internal_SBz
    ST          r10, ca_eddsa_verify_internal_SBt

; ==============================================================================
;   E = SHA512(ENC(R)||ENC(A)||M) mod q
; ==============================================================================
    LD          r25, eddsa_verify_input_message
    LD          r26, eddsa_verify_input_pubkey
    LD          r27, eddsa_verify_input_R

    SWE         r21, r25
    SWE         r22, r26
    SWE         r23, r27

    ; Padding
    MOVI        r20, 1
    ROR         r20, r20
    ORI         r20, r20, 0x300      ; length of message = 3*256 = 768 = 0x300

    HASH_IT
    HASH        r28, r20

    ; encode as little-endian and reduce mod q
    SWE         r28, r28
    SWE         r29, R29
    LD          r31, ca_q25519
    REDP        r28, r28, r29

; ==============================================================================
;   Q2 = E.A
; ==============================================================================

    ; Decompress ENC(A)
    LD          r31, ca_p25519
    MOV         r12, r26
    CALL        point_decompress_ed25519

    CMPI        r31,  0     ; Clear zero flag (r31 is for sure not 0);

.ifdef SPECT_ISA_VERSION_1
    CMPA        r1,  0
.endif
.ifdef SPECT_ISA_VERSION_2
    XORI        r1, r1, 0
.endif
    BRNZ        eddsa_verify_fail
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    ; Q2 = E . A
    CALL        spm_ed25519_short

; ==============================================================================
;   Q = Q1 - Q2
; ==============================================================================

    MOVI        r0,  0
    SUBP        r7,  r0,  r7
    SUBP        r10, r0,  r10

    LD          r11, ca_eddsa_verify_internal_SBx
    LD          r12, ca_eddsa_verify_internal_SBy
    LD          r13, ca_eddsa_verify_internal_SBz
    LD          r14, ca_eddsa_verify_internal_SBt

    CALL        point_add_ed25519
    MOV         r7,  r11
    MOV         r8,  r12
    MOV         r9,  r13

    ; ENC(Q)
    CALL        point_compress_ed25519

    MOVI        r0,  ret_op_success
    MOVI        r1,  1

; ==============================================================================
;   Final comparison -> ENC(R) = ENC(S.B - SHA512(R, A, M).A)
; ==============================================================================
    CMPI        r31,  0     ; Clear zero flag (r31 is for sure not 0)

.ifdef SPECT_ISA_VERSION_1
    LD          r31, ca_ffff
    SUBP        r2,  r23, r8
    CMPA        r2,  0
.endif
.ifdef SPECT_ISA_VERSION_2
    XOR         r2,  r23, r8
.endif
    BRZ         eddsa_verify_success
eddsa_verify_fail:
    MOVI        r2,  1
    ST          r2,  eddsa_verify_output_result
    JMP         set_res_word

eddsa_verify_success:
    MOVI        r2,  0xBA
    ROL8        r2,  r2
    ORI         r2,  r2,  0x11
    ROL8        r2,  r2
    ORI         r2,  r2,  0xFA
    ROL8        r2,  r2
    ORI         r2,  r2,  0xDE
    ROL8        r2,  r2
    ORI         r2,  r2,  0x0B
    ROL8        r2,  r2
    ORI         r2,  r2,  0x5E
    ROL8        r2,  r2
    ORI         r2,  r2,  0x55
    ROL8        r2,  r2
    ORI         r2,  r2,  0xED
    ST          r2,  eddsa_verify_output_result
    JMP         set_res_word
