.include const_rom_leyout.s
_start:
    CALL ecdsa_key_setup
    END

;.include    field_math/inv_p25519.s
;.include    field_math/inv_q256.s

.include    field_math/inv_p256.s
.include    ecc_math/point_add_p256.s
.include    ecc_math/point_dub_p256.s
.include    ecc_math/spm_p256.s
.include    ecc_crypto/ecdsa_key_setup.s

;.include    ecc_crypto/x25519.s