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
;
; ==============================================================================

spm_ed25519_long:
    ; (r7,  r8,  r9,  r10) = Q0 = "point at infinity O"
    MOVI    r7,  0
    MOVI    r8,  1
    MOVI    r9,  1
    MOVI    r10, 0

    MOVI    r30, 256

    ; scalar bits 511 downto 256
spm_ed25519_long_loop_511_256:
    ROL     r29, r29

    CSWAP   r7,  r11
    CSWAP   r8,  r12
    CSWAP   r9,  r13
    CSWAP   r10, r14

    CALL    point_add_ed25519
    CALL    point_dbl_ed25519

    CSWAP   r7,  r11
    CSWAP   r8,  r12
    CSWAP   r9,  r13
    CSWAP   r10, r14

    SUBI    r30, r30, 1
    BRNZ    spm_ed25519_long_loop_511_256

    MOVI    r30, 256

    ; scalar bits 255 downto 0
spm_ed25519_long_loop_255_0:
    ROL     r28, r28

    CSWAP   r7,  r11
    CSWAP   r8,  r12
    CSWAP   r9,  r13
    CSWAP   r10, r14

    CALL    point_add_ed25519
    CALL    point_dbl_ed25519

    CSWAP   r7,  r11
    CSWAP   r8,  r12
    CSWAP   r9,  r13
    CSWAP   r10, r14

    SUBI    r30, r30, 1
    BRNZ    spm_ed25519_long_loop_255_0

    RET
    