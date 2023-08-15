; ==============================================================================
;  file    ecc_math/curve25519/spm_curve25519.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Scalar Point Multiplication on Curve25519 with 512 bit scalar
; Uses CSWAP Montgomery Ladder method [https://eprint.iacr.org/2017/293]
; Uses diferential x-coordinate only addition/doubling
; 
; Inputs:
;               X    Z
;   Point P = (r11, r12)
;
;   Scalar k = (r28, r29)
;
; Output:
;                     X    Z
;   Point k.P     = (r7,  r8)
;   Point (k+1).P = (r9,  r10)
; 
; Expects:
;   Curve25519 prime in r31
;
; ==============================================================================

spm_curve25519:
    LD      r6,  ca_curve25519_a2d4
    MOV     r9,  r11
    MOV     r10, r12
    MOVI    r7,  1
    MOVI    r8,  0

    ; x0 = O = (r7, r8) 
    ; x1 = P = (r9, r10)
    ; P  = R = (r11, r12)

    MOVI r30, 256
spm_curve25519_loop_511_256:
    ROL     r29, r29
    CSWAP   r7,  r9
    CSWAP   r8,  r10

    CALL    point_xadd_curve25519
    CALL    point_xdbl_curve25519

    CSWAP   r7,  r9
    CSWAP   r8,  r10

    SUBI    r30, r30, 1
    BRNZ    spm_curve25519_loop_511_256

    MOVI    r30, 256

spm_curve25519_loop_255_0:
    ROL     r28, r28
    CSWAP   r7,  r9
    CSWAP   r8,  r10

    CALL    point_xadd_curve25519
    CALL    point_xdbl_curve25519

    CSWAP   r7,  r9
    CSWAP   r8,  r10

    SUBI    r30, r30, 1
    BRNZ    spm_curve25519_loop_255_0

    RET