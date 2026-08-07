; ==============================================================================
;  file    ecc_math/curve25519/spm_curve25519.s
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
; Scalar Point Multiplication on Curve25519 with 512 bit scalar
; Uses algorithm from https://datatracker.ietf.org/doc/html/rfc7748
; Adjusted to work with input point in projective coordinates.
; Recovers the y-coordinate at the end with correct sign.
;
; Inputs:
;               X    Z    Y
;   Point P = (r11, r12, r13)
;   Scalar k = (r28, r29)
;
; Output:
;                 X    Z    Y
;   Point k.P = (r7,  r8,  r9)
;
; Expects:
;   ---
;
; Modified registers:
;   r0 - r10,
;   r14 - r16,
;   r29 - r31
;
; Subroutines:
;   y_recovery_curve25519
;
; ==============================================================================

spm_curve25519:
    ; Store call check
    MOVI        r0,  call_check_level_1_id
    ST          r0,  ca_call_check_level_1

    ; Initialize TMAC DRNG for register precharge
    CALL        tmac_drng_init

    ; Load Curve25519 constants
    LD          r31, ca_p25519
    LD          r14, ca_x25519_a24

    ; Initialize point at infinity to (r7, r8) <- (1, 0) and store to position
    MOVI        r7,  1
    MOVI        r8,  0

    MOVI        r18, ca_spm_internal_Q0
    CALL        spm_curve25519_store_Q0

    ; Copy input point to (r9, r10) <- (Px, Pz) and store to position
    MOV         r9,  r11                            ; r9  <- x3
    MOV         r10, r12                            ; r10 <- z3

    XORI        r1,  r18, 0x100
    CALL        spm_curve25519_store_Q1

    MOVI        r17, 0x100                          ; scalar bit mask

    TMAC_RD     r19                                 ; fetch pseudorandom data

; === MAIN LOOP ================================================================
    MOVI        r15, 2

spm_curve25519_main_loop:
    MOVI        r30, 256                            ; i
    MOVI        r16, 0                              ; j
; --- INNER LOOP ---------------------------------------------------------------
    ROL8        r29, r29                            ; shift to position
spm_curve25519_inner_loop:
; --- INNER LOOP BODY -------
    ROL         r19, r19                            ; Randomize ALU_IN.A
    ROL         r29, r29                            ; Shift key
    ROL         r19, r19                            ; Randomize ALU_IN.A

    ; We have to first destroy the content of Q0, Q1 and r18 registers
    ; Otherwise XOR(k[i], k[i-1]) leaks through side-channel
    CALL        spm_curve25519_destroy_regs

    ROL         r19, r19                            ; Randomize ALU_IN.A
    AND         r18, r29, r17                       ; Get the scalar bit

    ROL         r1,  r19                            ; Randomize ALU_IN.A
    XOR         r19, r19, r1                        ; Refresh the precharge mask in r19
    ADDI        r18, r18, ca_spm_internal_Q0        ; Set pointer

    CALL        spm_curve25519_load_Q0
    XORI        r1,  r18, 0x100
    CALL        spm_curve25519_load_Q1

    ; --- Montgomery Step ---
    ADDP        r0,  r7,  r8                        ; A = x2 + z2
    MUL25519    r1,  r0,  r0                        ; AA = A^2
    SUBP        r2,  r7,  r8                        ; B = x2 - z2
    MUL25519    r3,  r2,  r2                        ; BB = B^2
    SUBP        r4,  r1,  r3                        ; E = AA - BB
    ADDP        r5,  r9,  r10                       ; C = x3 + z3
    SUBP        r6,  r9,  r10                       ; D = x3 - z3
    MUL25519    r5,  r5,  r2                        ; C = C * B
    MUL25519    r6,  r6,  r0                        ; D = D * A
    ADDP        r9,  r6,  r5                        ; x3 = D + C
    MUL25519    r9,  r9,  r9                        ; x3 = x3^2
    MUL25519    r9,  r12, r9                        ; x2 = z1 * x3  (adjustment for z1 != 1)
    SUBP        r10, r6,  r5                        ; z3 = D - C
    MUL25519    r10, r10, r10                       ; z3 = z3 * z3
    MUL25519    r10, r11, r10                       ; z3 = x1 * z3
    MUL25519    r7,  r1,  r3                        ; x2 = AA * BB
    MUL25519    r8,  r14, r4                        ; z2 = a24 * E
    ADDP        r8,  r1,  r8                        ; z2 = AA + z2
    MUL25519    r8,  r4,  r8                        ; z2 = E * z2
    ; -----------------------

    CALL        spm_curve25519_store_Q0
    XORI        r1,  r18, 0x100
    CALL        spm_curve25519_store_Q1
; ---------------------------

    ADDI        r16, r16, 1                         ; j++
    SUBI        r30, r30, 1                         ; i--
    BRNZ        spm_curve25519_inner_loop           ; i == 0 ?
    CMPI        r16, 256                            ; j == 256 ?
    BRNZ        spm_curve25519_invariant_failed
; ------------------------------------------------------------------------------

    MOV         r29, r28
    SUBI        r15, r15, 1
    BRNZ        spm_curve25519_main_loop
; ==============================================================================

    ; Load the results to (r7, r8) and (r9, r10)
    MOVI        r18, ca_spm_internal_Q0
    CALL        spm_curve25519_load_Q0
    XORI        r1,  r18, 0x100
    CALL        spm_curve25519_load_Q1

    ; Recover the y-coordinate with the correct sign
    CALL        y_recovery_curve25519

    MOVI        r0,  pass_val
    RET

spm_curve25519_invariant_failed:
    MOVI        r0,  fail_val
    RET

spm_curve25519_load_Q0:
    ; Loads point from address in r18 to (r7, r8)
    LDR         r7,  r18
    ADDI        r0,  r18, 0x20                          ; Use r0 to preserve r18
    LDR         r8,  r0
    RET

spm_curve25519_load_Q1:
    ; Loads point from address in r1 to (r9, r10)
    LDR         r9,  r1
    ADDI        r1,  r1,  0x20                          ; No need to preserve r1
    LDR         r10, r1
    RET

spm_curve25519_store_Q0:
    ; Loads point in (r7, r8) to address in r18
    STR         r7,  r18
    ADDI        r0,  r18, 0x20                          ; Use r0 to preserve r18
    STR         r8,  r0
    RET

spm_curve25519_store_Q1:
    ; Stores point in (r9, r10) to address in r1
    STR         r9,  r1
    ADDI        r1,  r1,  0x20                          ; No need to preserve r1
    STR         r10, r1
    RET

spm_curve25519_destroy_regs:
    ; Destroys the content of r7-r10 and r18 with pseudorandom data from TMAC DRNG
    ; We use TMAC DRNG only for r18 and then simple XOR to save time.
    TMAC_RD     r18
    XOR         r7,  r7,  r18
    XOR         r8,  r8,  r7
    XOR         r9,  r9,  r8
    XOR         r10, r10, r9
    RET
