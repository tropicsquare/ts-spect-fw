; ==============================================================================
;  file    routines_includes.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).

; ==============================================================================
;
; Includes of all source files for Application Firmware
;
; ==============================================================================

; ====================================================
; Field Math
; ====================================================
.include    field_math/256/inv_q256.s
.include    field_math/256/inv_p256.s
.include    field_math/25519/inv_p25519.s
.include    field_math/25519/sqrt_p25519.s

; ====================================================
; ECC Math
; ====================================================

; .......... Ed25519 ..........

.include   ecc_math/ed25519/point_compress_ed25519.s
.include   ecc_math/ed25519/point_decompress_ed25519.s
.include   ecc_math/ed25519/point_add_ed25519.s
.include   ecc_math/ed25519/point_dbl_ed25519.s
.include   ecc_math/ed25519/spm_ed25519_short.s
.include   ecc_math/ed25519/spm_ed25519_long.s
.include   ecc_math/ed25519/spm_ed25519_full_masked.s
.include   ecc_math/ed25519/point_check_ed25519.s

; .......... P256 ..........

.include   ecc_math/p256/point_add_p256.s
.include   ecc_math/p256/point_dbl_p256.s
.include   ecc_math/p256/spm_p256_short.s
.include   ecc_math/p256/spm_p256_long.s
.include   ecc_math/p256/spm_p256_full_masked.s
.include   ecc_math/p256/point_check_p256.s

; .......... Curve25519 ..........

.include    ecc_math/curve25519/get_y_curve25519.s
.include    ecc_math/curve25519/point_add_curve25519.s
.include    ecc_math/curve25519/point_check_curve25519.s
.include    ecc_math/curve25519/point_xadd_curve25519.s
.include    ecc_math/curve25519/point_xdbl_curve25519.s
.include    ecc_math/curve25519/spm_curve25519_long.s
.include    ecc_math/curve25519/y_recovery_curve25519.s

; ====================================================
; EdDSA Sequence
; ====================================================

.include    eddsa_sequence/eddsa_nonce_load_msg.s
.include    eddsa_sequence/eddsa_nonce_shift.s
.include    eddsa_sequence/eddsa_set_context.s
.include    eddsa_sequence/eddsa_nonce_init.s
.include    eddsa_sequence/eddsa_nonce_update.s
.include    eddsa_sequence/eddsa_nonce_finish.s
.include    eddsa_sequence/eddsa_r_part.s
.include    eddsa_sequence/eddsa_e_load_msg.s
.include    eddsa_sequence/eddsa_e_pad_mask.s
.include    eddsa_sequence/eddsa_e_at_once.s
.include    eddsa_sequence/eddsa_e_prep.s
.include    eddsa_sequence/eddsa_e_update.s
.include    eddsa_sequence/eddsa_e_finish.s
.include    eddsa_sequence/eddsa_finish.s

; ====================================================
; ECC Point Generation
; ====================================================

.include    ecc_point_generation/map_to_curve_elligator2_curve25519.s
.include    ecc_point_generation/point_generate_curve25519.s
.include    ecc_point_generation/point_generate_ed25519.s
.include    ecc_point_generation/sqrt_ratio_3mod4.s
.include    ecc_point_generation/map_to_curve_simple_swu.s
.include    ecc_point_generation/point_generate_p256.s


; ====================================================
; ECC Crypto
; ====================================================

.include    ecc_crypto/p256_key_setup.s
.include    ecc_crypto/ed25519_key_setup.s
.include    ecc_crypto/ecdsa_sign.s
.include    ecc_crypto/x25519_full_masked.s

; ====================================================
; SPECT Ops
; ====================================================

.include    ops/ecc_key_ops.s
.include    ops/ecdsa_ops.s
.include    ops/x25519_ops.s
.include    ops/clear.s

; ====================================================
; SPECT Debug Ops
; ====================================================
.ifdef DEBUG_OPS
.include    ops/debug.s
.endif

; ====================================================
; Others
; ====================================================
.include    others/tmac_shc_shn.s
.include    others/compose_exp_tag.s
.include    others/hash_to_field.s
.include    others/clear_data_buffs.s
