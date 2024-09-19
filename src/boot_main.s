; ==============================================================================
;  file    boot_main.s
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
; Top source for SPECT Boot Firmware
;
;   - eddsa_verify
;
; ==============================================================================

.include mem_layouts/mem_layouts_includes.s
.include constants/spect_ops_status.s
.include constants/spect_ops_constants.s
.include constants/spect_descriptors_constants.s
_start:
    LD      r0, ca_spect_cfg_word
    MOVI    r4, 0xFF
    AND     r0, r0, r4

    CMPI    r0, eddsa_verify_id
    BRZ     op_eddsa_verify

    MOVI    r0, ret_op_id_err
    MOVI    r1, 1

set_res_word:
    ROL8    r1, r1
    ROL8    r1, r1
    ADD     r0, r0, r1
    ST      r0, ca_spect_res_word
    END

op_eddsa_verify:
    JMP     eddsa_verify

.include    field_math/25519/inv_p25519.s
.include    ecc_math/ed25519/spm_ed25519_short.s
.include    ecc_math/ed25519/point_add_ed25519.s
.include    ecc_math/ed25519/point_dbl_ed25519.s
.include    ecc_crypto/eddsa_verify.s
.include    ecc_math/ed25519/point_compress_ed25519.s
.include    ecc_math/ed25519/point_decompress_ed25519.s
