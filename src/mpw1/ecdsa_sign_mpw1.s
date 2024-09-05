; ==============================================================================
;  file    mpw1/ecdsa_sign_mpw1.s
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
; ECDSA P-256 Sign for TROPIC01-MP1
;
; Input:
;   Private Key 'd' in r26
;   Message Digest z in r18
;
;   Random number for nonce 'k' in r27
;   Mask for projecive coordinates randomization in r16
;   Mask for scalar randomization in r17
;   Mask for s computatuion in r25
;
; Output:
;   ECDSA Signature (R,S) = (0x1020, 0x1040)
;   Status in r30
;
; Countermesures:
;   projective coordinates randomization (x, y, 1) = (tx, ty, t)
;   scalar randomization k = tq + k (mod q)
;   s-part computaion (z + rd)/k = (zt + rtd)/(kt) (mod q)
;
; ==============================================================================
;                               !!! ISAv1 ONLY !!!
; ==============================================================================

ecdsa_sign_mpw1:
; ==============================================================================
;   Reduce r27 mod q to get noce 'k' and randomize using r17
; ==============================================================================
    LD          r31, ca_q256
    MOVI        r28, 0
    REDP        r27, r28, r27

    CMPA        r27, 0
    BRZ         ecdsa_sign_fail_mpw1

    SCB         r28, r27, r17

; ==============================================================================
;   Load curve and randomize using r16
; ==============================================================================
    LD          r31, ca_p256
    LD          r12, ca_p256_xG
    LD          r13, ca_p256_yG

    MOVI        r0,  0x0
    REDP        r14, r0, r16

    CMPA        r14, 0
    BRZ         ecdsa_sign_fail_mpw1

    MUL256      r12, r12, r14
    MUL256      r13, r13, r14

; ==============================================================================
;   Compute r = [k.G]x mod q
; ==============================================================================
    LD          r8,  ca_p256_b

    CALL        spm_p256_long
    MOV         r1,  r11
    CALL        inv_p256
    MUL256      r12, r9,  r1

    LD          r31, ca_q256
    MOVI        r0, 0
    REDP        r12, r0, r12
    CMPA        r12, 0
    BRZ         ecdsa_sign_fail_mpw1

; ==============================================================================
;   Compute s = (z + r*d)/k mod q
;   Masked with t as (z*t + r*t*d) * (k*t)^(-1) mod q
; ==============================================================================
    MULP        r1,  r25, r27                   ; (kt)
    CALL        inv_q256                        ; (kt)^(-1)
    MULP        r10, r18, r25                   ; zt
    MULP        r11, r12, r25                   ; rt
    MULP        r11, r26, r11                   ; rtd
    ADDP        r10, r10, r11                   ; zt + rtd
    MULP        r10, r1,  r10                   ; (zt + rtd) / (kt)

    CMPA        r10, 0
    BRZ         ecdsa_sign_fail_mpw1

; ==============================================================================
;   Store
; ==============================================================================
    SWE         r12, r12
    SWE         r10, r10
    ST          r12, 0x1020
    ST          r10, 0x1040
    MOVI        r30, 0x01
    RET

; ==============================================================================
;   Fail
; ==============================================================================
ecdsa_sign_fail_mpw1:
    MOVI        r30, 0x0F
    RET
