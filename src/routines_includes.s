;.include    src/field_math/inv_q256.s
;.include    src/field_math/inv_p256.s
.include    src/field_math/inv_p25519.s

.include    src/ecc_math/point_compress_ed25519.s
.include    src/ecc_math/point_decompress_ed25519.s
;.include    src/ecc_math/point_add_p256.s
;.include    src/ecc_math/point_dbl_p256.s
.include    src/ecc_math/point_add_ed25519.s
.include    src/ecc_math/point_dbl_ed25519.s
;.include    src/ecc_math/spm_p256.s
.include    src/ecc_math/spm_ed25519_short.s

;.include    src/ecc_crypto/ecdsa_key_setup.s
;.include    src/ecc_crypto/ecdsa_sign.s
;.include    src/ecc_crypto/x25519.s
.include    src/ecc_crypto/eddsa_verify.s

.include    src/sha512/sha512_routines.s