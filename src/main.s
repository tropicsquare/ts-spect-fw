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

; ============================================================
; Curve25519 Random Point Generation
next_cmd_4:
    CMPI r0, curve25519_rpg_id
    BRNZ next_cmd_5
    LD      r1, ca_dst_template
    LD      r2, 0x0020              ; DST ID
    OR      r1, r1, r2
    ROL8    r1, r1
    CALL    curve25519_point_generate
    ST      r10, 0x1000 
    ST      r11, 0x1020
    ST      r12, 0x1040
    END 
; ============================================================
; ============================================================
; Ed25519 Random Point Generation
next_cmd_5:
    CMPI r0, ed25519_rpg_id
    BRNZ next_cmd_end
    LD      r1, ca_dst_template
    LD      r2, 0x0020              ; DST ID
    OR      r1, r1, r2
    ROL8    r1, r1
    CALL    ed25519_point_generate
    ST      r10, 0x1000 
    ST      r11, 0x1020
    ST      r12, 0x1040
    END 
; ============================================================

next_cmd_end:
    END

.include    field_math/inv_q256.s
;.include    field_math/inv_p256.s
.include    field_math/inv_p25519.s

.include    ecc_math/point_compress_ed25519.s
.include    ecc_math/point_decompress_ed25519.s
;.include   ecc_math/point_add_p256.s
;.include   ecc_math/point_dub_p256.s
.include    ecc_math/point_add_ed25519.s
.include    ecc_math/point_dub_ed25519.s
;.include   ecc_math/spm_p256.s
.include    ecc_math/spm_ed25519_short.s

.include    ecc_point_generation/hash_to_field_p25519.s
.include    ecc_point_generation/map_to_curve_elligator2_curve25519.s
.include    ecc_point_generation/point_generate_curve25519.s
.include    ecc_point_generation/point_generate_ed25519.s
.include    ecc_point_generation/compose_exp_tag.s

;.include   ecc_crypto/ecdsa_key_setup.s
;.include   ecc_crypto/ecdsa_sign.s
;.include   ecc_crypto/x25519.s
.include    ecc_crypto/eddsa_verify.s

.include    sha512/sha512_routines.s

