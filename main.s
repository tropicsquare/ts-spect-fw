.include const_rom_leyout.s
.include data_ram_in_leyout.s
_start:
    LD r0, ca_command

    CMPI r0, 0
    BRNZ next_cmd_1
    CALL ecdsa_key_setup
    END
next_cmd_1:
    CMPI r0, 1
    BRNZ next_cmd_2
    CALL ecdsa_sign
    END
next_cmd_2:
    CMPI r0, 2
    BRNZ next_cmd_3
    CALL x25519
    END

next_cmd_3:
    END

.include    field_math/inv_q256.s
.include    field_math/inv_p256.s
.include    field_math/inv_p25519.s

.include    ecc_math/point_add_p256.s
.include    ecc_math/point_dub_p256.s
.include    ecc_math/spm_p256.s

.include    ecc_crypto/ecdsa_key_setup.s
.include    ecc_crypto/ecdsa_sign.s
.include    ecc_crypto/x25519.s