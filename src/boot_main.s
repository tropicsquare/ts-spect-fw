; ==============================================================================
;  file    boot_main.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Top source for SPECT Boot Firmware
;
;   - sha512_init
;   - sha512_update
;   - sha512_final
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

    CMPI    r0, sha512_update_id
    BRZ     op_sha512_update

    CMPI    r0, sha512_init_id
    BRZ     op_sha512_init

    CMPI    r0, sha512_final_id
    BRZ     op_sha512_final

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
    JMP     set_res_word

.include    ops/sha512_ops.s
.include    ecc_crypto/eddsa_verify.s
.include    ecc_math/ed25519/spm_ed25519_short.s
.include    ecc_math/ed25519/point_add_ed25519.s
.include    ecc_math/ed25519/point_dbl_ed25519.s
.include    ecc_math/ed25519/point_compress_ed25519.s
.include    ecc_math/ed25519/point_decompress_ed25519.s
.include    field_math/25519/inv_p25519.s