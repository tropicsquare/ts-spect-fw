.include mem_leyouts/mem_leyouts_includes.s
.include spect_ops_constants.s

_start:
    LD r0, ca_command

    CMPI r0, sha512_init_id
    BRNZ next_cmd_1
    JMP sha512_init
next_cmd_1:
    CMPI r0, sha512_update_id
    BRNZ next_cmd_2
    JMP sha512_update
next_cmd_2:
    CMPI r0, sha512_final_id
    BRNZ next_cmd_3
    JMP sha512_final

next_cmd_3:
    CMPI r0, eddsa_verify_id
    BRNZ next_cmd_4
    JMP eddsa_verify

next_cmd_4:
    END

.include    field_math/inv_q256.s
.include    field_math/inv_p256.s
.include    field_math/inv_p25519.s

.include    ecc_math/point_compress_ed25519.s
.include    ecc_math/point_decompress_ed25519.s
;.include   ecc_math/point_add_p256.s
;.include   ecc_math/point_dub_p256.s
.include    ecc_math/point_add_ed25519.s
.include    ecc_math/point_dub_ed25519.s
;.include   ecc_math/spm_p256.s
.include    ecc_math/spm_ed25519_short.s

;.include   ecc_crypto/ecdsa_key_setup.s
;.include   ecc_crypto/ecdsa_sign.s
;.include   ecc_crypto/x25519.s
.include    ecc_crypto/eddsa_verify.s

.include    sha512/sha512_routines.s
