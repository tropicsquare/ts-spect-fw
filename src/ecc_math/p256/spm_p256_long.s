; ==============================================================================
;  file    ecc_math/p256/spm_p256_long.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Scalar Point Multiplication on curve P-256
; Uses CSWAP Montgomery Ladder method [https://eprint.iacr.org/2017/293]
;
; Imputs:
;   Point P = (r12, r13, r14)
;   Scalar k = (r28,r29)
;
; Output:
;   Point Q = (r9,r10,r11)
;
; Expects:
;   p256 prime in r31
;   P-256 parameter b in r8
;
; Intermediate value registers:
;   r0-r7 -> intermediate values for point addition/doubling
;   r8 -> parameter b
;   (r9, r10, r11) -> Q0
;   r30 -> counter
;
; ==============================================================================

spm_p256_long:
    MOVI r9,  0 ;\
    MOVI r10, 1 ;|-> (r9, r10, r11) = Q0 = "point at infinity O"
    MOVI r11, 0 ;/

    MOVI r30, 256
spm_p256_long_loop_511_256:
    ROL r29, r29

    CSWAP r9,  r12
    CSWAP r10, r13
    CSWAP r11, r14

    CALL point_add_p256
    CALL point_dbl_p256

    CSWAP r9,  r12
    CSWAP r10, r13
    CSWAP r11, r14

    SUBI r30, r30, 1
    BRNZ spm_p256_long_loop_511_256

    MOVI r30, 256
spm_p256_long_loop_255_0:
    ROL r28, r28

    CSWAP r9,  r12
    CSWAP r10, r13
    CSWAP r11, r14

    CALL point_add_p256
    CALL point_dbl_p256

    CSWAP r9,  r12
    CSWAP r10, r13
    CSWAP r11, r14

    SUBI r30, r30, 1
    BRNZ spm_p256_long_loop_255_0

    RET
    