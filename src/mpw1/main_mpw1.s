; ==============================================================================
;  file    mpw1/main_mpw1.s
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
;  Main for MPW1 tests
;
;   Op at 0x0000
;   Return code at 0x1000
;
;   - ECDSA Sign
;       0x0020  Private Key 'd'
;       0x0040  Message Digest z
;
;       0x0060  Random number for nonce 'k'
;       0x0080  Mask for projecive coordinates randomization
;       0x00A0  Mask for scalar randomization
;       0x00C0  Mask for s computatuion
;
; ==============================================================================

.include ops_id_mpw1.s
.include ../mem_layouts/constants_data_in_layout.s

_start:
    LD      r0,  0x0000

    CMPI    r0,  ecdsa_sign_id_mpw1
    BRZ     op_ecdsa_sign_mpw1

    CMPI    r0,  p256_scm_pure_id_mpw1
    BRZ     p256_scm_mpw1

    CMPI    r0,  p256_scm_masked_id_mpw1
    BRZ     p256_scm_mpw1

    CMPI    r0,  ed25519_scm_pure_id_mpw1
    BRZ     ed25519_scm_mpw1

    CMPI    r0,  ed25519_scm_masked_id_mpw1
    BRZ     ed25519_scm_mpw1

    CMPI    r0,  x25519_scm_pure_id_mpw1
    BRZ     x25519_scm_mpw1

    CMPI    r0,  x25519_scm_masked_id_mpw1
    BRZ     x25519_scm_mpw1

    JMP     op_err_mpw1

; ==============================================================================
;   ECDSA
; ==============================================================================
op_ecdsa_sign_mpw1:
    LD      r26, 0x0020
    LD      r18, 0x0040
    SWE     r18, r18
    LD      r27, 0x0060
    LD      r16, 0x0080
    LD      r17, 0x00A0
    LD      r25, 0x00C0
    CALL    ecdsa_sign_mpw1
    ST      r30, 0x1000
    END

; ==============================================================================
;   P-256
; ==============================================================================
p256_scm_mpw1:
    LD      r31, ca_p256
    LD      r9,  0x0040
    LD      r10, 0x0060
    MOVI    r11, 1

    CALL    point_check_p256
    BRNZ    scm_err_mpw1

    LD      r28, 0x0020

    LD      r0,  0x0000
    CMPI    r0, p256_scm_masked_id_mpw1
    BRZ     p256_scm_masked_mpw1

p256_scm_pure_mpw1:
    MOV     r12, r9
    MOV     r13, r10
    MOV     r14, r11

    LD      r8,  ca_p256_b
    CALL    spm_p256_short
    JMP     p256_scm_mpw1_end

p256_scm_masked_mpw1:
    LD      r14, 0x0080
    MOVI    r0,  0
    REDP    r14, r0,  r14
    CMPA    r14, 0
    BRZ     scm_err_mpw1

    MUL256  r12, r9,  r14
    MUL256  r13, r10, r14

    LD      r31, ca_q256
    LD      r1,  0x00A0
    SCB     r28, r28, r1

    LD      r31, ca_p256
    LD      r8,  ca_p256_b
    CALL    spm_p256_long

p256_scm_mpw1_end:
    CALL        point_check_p256
    BRNZ        scm_err_mpw1

    MOV         r1,  r11
    CALL        inv_p256
    MUL256      r9,  r9,  r1
    MUL256      r10, r10, r1

    MOVI        r30, 0x01
    ST          r30, 0x1000
    ST          r9,  0x1040
    ST          r10, 0x1060
    END

; ==============================================================================
;   Ed25519
; ==============================================================================
ed25519_scm_mpw1:
    LD          r31, ca_p25519
    LD          r7,  0x0040
    LD          r8,  0x0060
    MOVI        r9,  1
    MUL25519    r10, r7,  r8

    LD          r6,  ca_ed25519_d
    CALL        point_check_ed25519
    BRNZ        scm_err_mpw1

    LD          r28, 0x0020

    LD          r0,  0x0000
    CMPI        r0, ed25519_scm_masked_id_mpw1
    BRZ         ed25519_scm_masked_mpw1
ed25519_scm_pure_mpw1:
    MOV         r11, r7
    MOV         r12, r8
    MOV         r13, r9
    MOV         r14, r10

    CALL        spm_ed25519_short
    JMP         ed25519_scm_mpw1_end

ed25519_scm_masked_mpw1:
    LD          r13, 0x0080
    MOVI        r0,  0
    REDP        r13, r0,  r13
    CMPA        r13, 0
    BRZ         scm_err_mpw1

    MUL25519    r11, r7,  r13
    MUL25519    r12, r8,  r13
    MUL25519    r14, r10, r13

    LD          r31, ca_q25519
    LD          r1,  0x00A0
    SCB         r28, r28, r1

    LD          r6,  ca_ed25519_d
    LD          r31, ca_p25519
    CALL        spm_ed25519_long

ed25519_scm_mpw1_end:
    CALL        point_check_ed25519
    BRNZ        scm_err_mpw1

    MOV         r1,  r9
    CALL        inv_p25519
    MUL25519    r7,  r7,  r1
    MUL25519    r8,  r8,  r1

    MOVI        r30, 0x01
    ST          r30, 0x1000
    ST          r7,  0x1040
    ST          r8,  0x1060
    END

x25519_scm_mpw1:
    LD          r28, 0x0020
    LD          r11, 0x0040
    MOVI        r12, 1

    ROL8        r27, r28
    ANDI        r27, r27, 0x83f
    ORI         r27, r27, 0x040
    ROR8        r28, r27

    LD          r31, ca_p25519

    CMPI        r0,  x25519_scm_masked_id_mpw1
    BRZ         x25519_scm_masked_mpw1
x25519_scm_pure_mpw1:
    CALL        spm_curve25519_short
    JMP         x25519_scm_mpw1_end

x25519_scm_masked_mpw1:
    LD          r12, 0x0080
    MOVI        r0,  0
    REDP        r12, r0,  r12
    CMPA        r12, 0
    BRZ         scm_err_mpw1
    MUL25519    r11, r11, r12

    LD          r31, ca_q25519
    LD          r1,  0x00A0
    SCB         r28, r28, r1

    LD          r31, ca_p25519
    CALL        spm_curve25519_long

x25519_scm_mpw1_end:
    MOV         r1,  r8
    CALL        inv_p25519
    MUL25519    r7,  r7,  r1
    MOVI        r30, 0x1
    ST          r30, 0x1000
    ST          r7,  0x1040
    END

scm_err_mpw1:
    MOVI    r30, 0x0F
    ST      r30, 0x1000
    END

op_err_mpw1:
    MOVI    r0,  0xF0
    ST      r0,  0x1000
    END

.include    ../field_math/256/inv_q256.s
.include    ../field_math/256/inv_p256.s
.include    ../field_math/25519/inv_p25519.s

.include    ../ecc_math/p256/point_add_p256.s
.include    ../ecc_math/p256/point_dbl_p256.s
.include    ../ecc_math/p256/point_check_p256.s
.include    ../ecc_math/p256/spm_p256_short.s
.include    ../ecc_math/p256/spm_p256_long.s

.include    ../ecc_math/ed25519/point_add_ed25519.s
.include    ../ecc_math/ed25519/point_dbl_ed25519.s
.include    ../ecc_math/ed25519/point_check_ed25519.s
.include    ../ecc_math/ed25519/spm_ed25519_short.s
.include    ../ecc_math/ed25519/spm_ed25519_long.s

.include    ../ecc_math/curve25519/point_xadd_curve25519.s
.include    ../ecc_math/curve25519/point_xdbl_curve25519.s
.include    ../ecc_math/curve25519/spm_curve25519_short.s
.include    ../ecc_math/curve25519/spm_curve25519_long.s

.include    ecdsa_sign_mpw1.s
