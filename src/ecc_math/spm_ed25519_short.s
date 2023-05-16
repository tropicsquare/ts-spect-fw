; Scalar Point Multiplication on curve Ed25519
; Uses CSWAP Montgomery Ladder method [https://eprint.iacr.org/2017/293]
;
; Imputs:
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
; Intermediate value registers:
;   r0-r4 -> intermediate values for point addition/doubling
;   r6 -> parameter d
;   (r7,  r8,  r9,  r10) -> Q0
;   r30 -> counter

spm_ed25519_short:
    MOVI r7,  0 ;\
    MOVI r8,  1 ;|-> (r7,  r8,  r9,  r10) = Q0 = "point at infinity O"
    MOVI r9,  1 ;|
    MOVI r10, 0 ;/

    MOVI r30, 256
spm_ed25519_short_loop:
    ROL r28, r28

    CSWAP r7,  r11
    CSWAP r8,  r12
    CSWAP r9,  r13
    CSWAP r10, r14

    CALL point_add_ed25519
    CALL point_dub_ed25519

    CSWAP r7,  r11
    CSWAP r8,  r12
    CSWAP r9,  r13
    CSWAP r10, r14

    SUBI r30, r30, 1
    BRNZ spm_ed25519_short_loop

    RET
    