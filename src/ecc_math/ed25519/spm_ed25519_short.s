; ==============================================================================
;  file    ecc_math/ed25519/spm_ed25519_short.s
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
; Scalar Point Multiplication on curve Ed25519 with 256 bit scalar
; Uses CSWAP Montgomery Ladder method [https://eprint.iacr.org/2017/293]
;
; Inputs:
;   Point P = (r11, r12, r13, r14)
;   Scalar k = (r28)
;
; Output:
;   Point Q = (r7,  r8,  r9,  r10)
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

spm_ed25519_short:
    ; Store call check
    MOVI        r0,  call_check_level_1_id
    ST          r0,  ca_call_check_level_1

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

    MOVI        r30, 256    ; i
    MOVI        r16, 0      ; j

spm_ed25519_short_loop:
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

    ADDI        r16, r16, 1     ; j++
    SUBI        r30, r30, 1     ; i--
    BRNZ        spm_ed25519_short_loop       ; i == 0 ?
    CMPI        r16, 256                     ; j == 256 ?
    BRNZ        spm_ed25519_short_invariant_failed

; === Check Montgomery ladder invariant ===
    ; R16 is 0 from the counter
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
    BRNZ        spm_ed25519_short_invariant_failed
    XOR         r30, r1,  r12
    BRNZ        spm_ed25519_short_invariant_failed

    MOVI        r0,  pass_val
    RET

spm_ed25519_short_invariant_failed:
    MOVI        r0,  fail_val
    RET
