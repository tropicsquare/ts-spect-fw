_start:
    CALL x25519
    END

.include    field_math/inv_p25519.s
.include    ecc_crypto/x25519.s