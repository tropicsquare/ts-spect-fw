; ==============================================================================
;  file    mpw1/main_mpw1.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license). 
; ==============================================================================
;
;  Main for MPW1 tests
;
;   Op at 0x0000
;   Return code at 0x1000
;
;   - ECDSA Sign
;       0x0020  Private Key 'd'
;       0x0040  Message Digest z
;
;       0x0060  Random number for nonce 'k'
;       0x0080  Mask for projecive coordinates randomization
;       0x00A0  Mask for scalar randomization
;       0x00C0  Mask for s computatuion
;
; ==============================================================================

.include ops_id_mpw1.s
.include ../mem_layouts/constants_data_in_layout.s

_start:
    LD      r0,  0x0000

    CMPI    r0,  ecdsa_sign_id_mpw1
    BRZ     op_ecdsa_sign_mpw1

    CMPI    r0,  p256_scm_pure_id_mpw1
    BRZ     p256_scm_pure_mpw1

    CMPI    r0,  p256_scm_masked_id_mpw1
    BRZ     p256_scm_masked_mpw1

    CMPI    r0,  ed25519_scm_pure_id_mpw1
    BRZ     ed25519_scm_pure_mpw1

    CMPI    r0,  ed25519_scm_masked_id_mpw1
    BRZ     ed25519_scm_masked_mpw1

    CMPI    r0,  x25519_scm_pure_id_mpw1
    BRZ     x25519_scm_pure_mpw1

    CMPI    r0,  x25519_scm_masked_id_mpw1
    BRZ     x25519_scm_masked_mpw1

    JMP     op_err_mpw1

op_ecdsa_sign_mpw1:
    LD      r26, 0x0020
    LD      r18, 0x0040
    SWE     r18, r18
    LD      r27, 0x0060
    LD      r16, 0x0080
    LD      r17, 0x00A0
    LD      r25, 0x00C0
    CALL    ecdsa_sign_mpw1
    ST      r30, 0x1000
    END

p256_scm_pure_mpw1:

p256_scm_masked_mpw1:

ed25519_scm_pure_mpw1:

ed25519_scm_masked_mpw1:

x25519_scm_pure_mpw1:

x25519_scm_masked_mpw1:


op_err_mpw1:
    MOVI    r0,  0xF0
    ST      r0,  0x1000
    END

.include    ../field_math/256/inv_q256.s
.include    ../field_math/256/inv_p256.s

.include    ../ecc_math/p256/point_add_p256.s
.include    ../ecc_math/p256/point_dbl_p256.s
.include    ../ecc_math/p256/spm_p256_long.s

.include    ecdsa_sign_mpw1.s
