; ==============================================================================
;  file    field_math/25519/sqrt_p25519.s
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
; Square root in GF(p25519)
;
; Inputs:
;   Z in register r1
;
; Outputs:
;   sqrt(Z), if Z is square in GF(p25519) in r1
;   1 or 0 in r0, if Z is square in GF(p25519)
;
; Expects:
;   p25519 in register r31
;
; Computes Z^((p - 1) / 2) to r0
; Computes Z^((p + 3) / 8) or Z^((p + 3) / 8) * 2^((p-1) / 4) to r1
;
; ==============================================================================

sqrt_p25519:
    CALL        inv_p25519_250
    MUL25519    r0, r2, r2
    MUL25519    r0, r0, r0
    MUL25519    r0, r0, r1
    MUL25519    r0, r0, r0
    MUL25519    r0, r0, r1
    MUL25519    r0, r0, r0

    MUL25519    r2, r2, r2
    MUL25519    r2, r2, r1
    MUL25519    r2, r2, r2

    LD          r4, ca_p25519_c3
    MUL25519    r3, r2, r4

    MUL25519    r4, r2, r2
.ifdef SPECT_ISA_VERSION_1
    SUBP        r4,  r4,  r1
    CMPA        r4,  0
.endif
.ifdef SPECT_ISA_VERSION_2
    XOR         r4, r4, r1
.endif

    BRNZ        sqrt_p25519_final_correction
    MOV         r1, r2
    RET
sqrt_p25519_final_correction:
    MOV         r1, r3
    RET
