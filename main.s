.include mem_leyout.s
_start:
    ;CALL x25519
    LD r1, c_num
    CALL inv_q256
    ST r1, 0x1000
    END

;.include    field_math/inv_p25519.s
;.include    field_math/inv_p256.s
.include    field_math/inv_q256.s

;.include    ecc_crypto/x25519.s