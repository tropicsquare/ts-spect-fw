; ==============================================================================
;  file    ecc_math/ed25519/spm_ed25519_long.s
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
; Scalar point multiplication on curve Ed25519 with 512 bit scalar
; Uses CSWAP Montgomery Ladder method [https://eprint.iacr.org/2017/293]
;
; Inputs:
;   Point P = (r11, r12, r13, r14)
;   Scalar k = (r28, r29)
;
; Output:
;   Point Q = (r7,  r8,  r9,  r10)
;   Final invariant check: r0
;
; Expects:
;   Ed25519 prime in r31
;   Ed25519 parameter d in r6
;
; Modified registers:
;   r0-r4 -> intermediate values for point addition/doubling
;   r6 -> parameter d
;   (r7,  r8,  r9,  r10) -> Q0
;   r30 -> counter
;
; Subroutines:
;   point_add_ed25519
;   point_dbl_ed25519
;
; ==============================================================================

spm_ed25519_long:
    ; Store P for Montgomery ladder invariant check (Q1 - Q0 = P)
    ; No need of T coordinate for the check
    ST          r11, ca_spm_internal_Px
    ST          r12, ca_spm_internal_Py
    ST          r13, ca_spm_internal_Pz

    ; (r7,  r8,  r9,  r10) = Q0 = "point at infinity O"
    MOVI        r7,  0
    MOVI        r8,  1
    MOVI        r9,  1
    MOVI        r10, 0

    MOVI        r30, 256

    GRV         r15

    ; scalar bits 511 downto 256
spm_ed25519_long_loop_511_256:
    ROL         r15, r15
    ROL         r29, r29

    CSWAP       r7,  r11
    CSWAP       r8,  r12
    CSWAP       r9,  r13
    CSWAP       r10, r14

    CALL        point_add_ed25519
    CALL        point_dbl_ed25519

    CSWAP       r7,  r11
    CSWAP       r8,  r12
    CSWAP       r9,  r13
    CSWAP       r10, r14

    SUBI        r30, r30, 1
    BRNZ        spm_ed25519_long_loop_511_256

    MOVI        r30, 256

    ; scalar bits 255 downto 0
spm_ed25519_long_loop_255_0:
    ROL         r15, r15
    ROL         r28, r28

    CSWAP       r7,  r11
    CSWAP       r8,  r12
    CSWAP       r9,  r13
    CSWAP       r10, r14

    CALL        point_add_ed25519
    CALL        point_dbl_ed25519

    CSWAP       r7,  r11
    CSWAP       r8,  r12
    CSWAP       r9,  r13
    CSWAP       r10, r14

    SUBI        r30, r30, 1
    BRNZ        spm_ed25519_long_loop_255_0

    ; === Check Montgomery ladder invariant ===
    MOVI        r30,  0
    SUBP        r7,  r30, r7                    ;
    SUBP        r10, r30, r10                   ; Q0 -> -Q0

    CALL        point_add_ed25519               ; -Q0 + Q1 -> (r11, r12, r13, r14)

    ; Fix the Q0 back
    SUBP        r7,  r30, r7
    SUBP        r10, r30, r10

    ; Load the input point P
    LD          r0,  ca_spm_internal_Px
    LD          r1,  ca_spm_internal_Py
    LD          r2,  ca_spm_internal_Pz

    ; Convert the two points to common Z-coordinate
    MUL25519    r0,  r0,  r13
    MUL25519    r1,  r1,  r13
    MUL25519    r11, r11, r2
    MUL25519    r12, r12, r2

    ; Compare X and Y coordinates
    XOR         r30, r0,  r11
    BRNZ        spm_ed25519_long_invariant_failed
    XOR         r30, r1,  r12
    BRNZ        spm_ed25519_long_invariant_failed

    MOVI        r0,  0
    RET

spm_ed25519_long_invariant_failed:
    MOVI        r0,  1
    RET
