; ==============================================================================
;  file    ecc_point_generation/point_generate_p256.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Point Generate on NIST curve P-256
;
; Input:
;   0x02 || DST || 0x1E in r1
;
; Output:
;   Random point (x, y, z) on cirve P-256 -- (r17, r18, r19)
;
; Expects:
;   P-256 prime in r31
;
; Intermediate registers:
;   r0, ..., r
;
; See spect_fw/str2point.md for detailed description.
;
; ==============================================================================
p256_point_generate:
    GRV     r2
    CALL    hash_to_field

    CALL    map_to_curve_simple_swu
    XORI    r30, r19, 0
    BRZ     p256_point_generate

    RET
