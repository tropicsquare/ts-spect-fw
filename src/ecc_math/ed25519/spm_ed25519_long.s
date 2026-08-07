; ==============================================================================
;  file    ecc_math/ed25519/spm_ed25519_long.s
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
; Scalar point multiplication on curve Ed25519 with 512 bit scalar
;
; Inputs:
;   Point P = (ca_spm_internal_Px/y/z/t)
;   Scalar k = (r28, r29)
;
; Output:
;   Point Q = (r7,  r8,  r9,  r10)
;   Final invariant check: r0
;
; Expects:
;   ---
;
; Modified registers:
;   r0-r4 -> intermediate values for point addition/doubling
;   r6 -> parameter d
;   (r7,  r8,  r9,  r10) -> Q0
;   r15, r16, r30 -> counters
;   r29
;
;   r0 - r4,
;   r6 - r16,
;   r29 - r31
;   !!! Destroys the masked scalar in (r28, r29) !!!
;
; Subroutines:
;   point_add_ed25519
;   point_dbl_ed25519
;
; ==============================================================================

spm_ed25519_long:
    ; Store call check
    MOVI        r0,  call_check_level_1_id
    ST          r0,  ca_call_check_level_1

    ; Initialize TMAC DRNG for register precharge
    CALL    tmac_drng_init

    ; Load base point
    LD          r11, ca_spm_internal_Px
    LD          r12, ca_spm_internal_Py
    LD          r13, ca_spm_internal_Pz
    LD          r14, ca_spm_internal_Pt

    MOVI        r1,  ca_spm_internal_Q1
    CALL        spm_ed25519_long_store_Q1

    ; Load parameter b
    LD          r6,  ca_ed25519_d

    ; Load curve prime p
    LD          r31, ca_p25519

    ; (r7,  r8,  r9,  r10) = Q0 = "point at infinity O"
    MOVI        r7,  0
    MOVI        r8,  1
    MOVI        r9,  1
    MOVI        r10, 0
    MOVI        r18, ca_spm_internal_Q0
    CALL        spm_ed25519_long_store_Q0

    MOVI        r17, 0x100                              ; scalar bit mask

    TMAC_RD     r19                                     ; fetch pseudorandom data

; === MAIN LOOP ================================================================
    MOVI        r15, 2
spm_ed25519_long_main_loop:
    MOVI        r30, 256                                ; i = 256
    MOVI        r16, 0                                  ; j = 0
; --- INNER LOOP ---------------------------------------------------------------
    ROL8        r29, r29                                ; shift to position
spm_ed25519_long_loop:
; --- INNER LOOP BODY -------
    ROL         r19, r19                                ; Randomize ALU_IN.A
    ROL         r29, r29                                ; Shift key
    ROL         r19, r19                                ; Randomize ALU_IN.A

    ; We have to first destroy the content of Q0, Q1 and r18 registers
    ; Otherwise XOR(k[i], k[i-1]) leaks through side-channel
    CALL        spm_ed25519_long_destroy_regs

    ROL         r19, r19                                ; Randomize ALU_IN.A
    AND         r18, r29, r17                           ; Get the scalar bit

    ROL         r1,  r19                                ; Randomize ALU_IN.A
    XOR         r19, r19, r1                            ; Refresh the precharge mask in r19
    ADDI        r18, r18, ca_spm_internal_Q0

    CALL        spm_ed25519_long_load_Q0
    XORI        r1,  r18, 0x100
    CALL        spm_ed25519_long_load_Q1

    CALL        point_add_ed25519
    CALL        point_dbl_ed25519

    CALL        spm_ed25519_long_store_Q0
    XORI        r1,  r18, 0x100
    CALL        spm_ed25519_long_store_Q1
; ---------------------------

    ADDI        r16, r16, 1                             ; j++
    SUBI        r30, r30, 1                             ; i--
    BRNZ        spm_ed25519_long_loop                   ; i == 0 ?
    CMPI        r16, 256                                ; j == 256 ?
    BRNZ        spm_ed25519_long_invariant_failed
; ------------------------------------------------------------------------------

    MOV         r29, r28
    SUBI        r15, r15, 1
    BRNZ        spm_ed25519_long_main_loop
; ==============================================================================

    ; === Check Montgomery ladder invariant ===
    MOVI        r18, ca_spm_internal_Q0
    CALL        spm_ed25519_long_load_Q0
    MOVI        r1, ca_spm_internal_Q1
    CALL        spm_ed25519_long_load_Q1

    ; r30 is 0 from the loop
    SUBP        r7,  r30,  r7                           ;
    SUBP        r10, r30,  r10                          ; Q0 -> -Q0

    CALL        point_add_ed25519                       ; -Q0 + Q1 -> (r11, r12, r13, r14)

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

    MOVI        r0,  pass_val
    RET

spm_ed25519_long_invariant_failed:
    MOVI        r0,  fail_val
    RET

spm_ed25519_long_load_Q0:
    ; Loads point from address in r18 to (r7, r8, r9, r10)
    LDR         r7,  r18
    ADDI        r0,  r18, 0x20                          ; Use r0 to preserve r18
    LDR         r8,  r0
    ADDI        r0,  r0,  0x20
    LDR         r9,  r0
    ADDI        r0,  r0,  0x20
    LDR         r10, r0
    RET

spm_ed25519_long_load_Q1:
    ; Loads point from address in r1 to (r11, r12, r13, r14)
    LDR         r11, r1
    ADDI        r1,  r1,  0x20                          ; No need to preserve r1
    LDR         r12, r1
    ADDI        r1,  r1,  0x20
    LDR         r13, r1
    ADDI        r1,  r1,  0x20
    LDR         r14, r1
    RET

spm_ed25519_long_store_Q0:
    ; Loads point in (r7, r8, r9, r10) to address in r18
    STR         r7,  r18
    ADDI        r0,  r18, 0x20                          ; Use r0 to preserve r18
    STR         r8,  r0
    ADDI        r0,  r0,  0x20
    STR         r9,  r0
    ADDI        r0,  r0,  0x20
    STR         r10, r0
    RET

spm_ed25519_long_store_Q1:
    ; Stores point in (r11, r12, r13, r14) to address in r1
    STR         r11, r1
    ADDI        r1,  r1,  0x20                          ; No need to preserve r1
    STR         r12, r1
    ADDI        r1,  r1,  0x20
    STR         r13, r1
    ADDI        r1,  r1,  0x20
    STR         r14, r1
    RET

spm_ed25519_long_destroy_regs:
    ; Destroys the content of r7-r14 and r18 with pseudorandom data from TMAC DRNG
    ; We use TMAC DRNG only for r18 and then simple XOR to save time.
    TMAC_RD     r18
    XOR         r7,  r7,  r18
    XOR         r8,  r8,  r7
    XOR         r9,  r9,  r8
    XOR         r10, r10, r9
    XOR         r11, r11, r10
    XOR         r12, r12, r11
    XOR         r13, r13, r12
    XOR         r14, r14, r13
    RET
