; ==============================================================================
;  file    ecc_point_generation/point_generate_ed25519.s
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Point Generate on Ed25519
;
; Input:
;   0x02 || DST || 0x1E in r1
;
; Output:
;   Random point (x, y, z, t) on Ed25519 -- (r11, r12, r13, r14)
;
; Intermediate value registers:
;   r0,..,r14
; 
; See spect_fw/str2point.md for detailed description.
;
; ==============================================================================

ed25519_point_generate:
    LD          r31, ca_p25519
    GRV         r2
    CALL        hash_to_field                   ; r0 = x in GF(2^255 - 19)

    CALL        map_to_curve_elligator2_curve25519
    ; (r3, r7, r11, r8) = (xMn, xMd, yMn, 1)
    XORI        r30, r7, 0
    BRZ         ed25519_point_generate

    ; r0    tv1
    ; r10   xn, x
    ; r13   xd, z
    ; r11   yn, y
    ; r14   yd

    LD          r30, ca_pg_map2ed25519_c5
                                                ; xn = xMn * yMd    (yMd = 1 every time)
    MUL25519    r10, r3,  r30                   ; xn = xn * c5
    MUL25519    r13, r7,  r11                   ; xd = xMd * yMn    xn / xd = c1 * xM / yM 
    SUBP        r12, r3,  r7                    ; yn = xMn - xMd
    ADDP        r14, r3,  r7                    ; yd = xMn + xMd    (n / d - 1) / (n / d + 1) = (n - d) / (n + d)
    MUL25519    r0,  r13, r14                   ; tv1 = xd * yd = z'
    XORI        r30, r0,  0                     ; e = tv1 == 0
    BRZ         ed25519_point_generate
    
    MUL25519    r11, r10, r14                   ; x' = xn * yd
    MUL25519    r12, r12, r13                   ; y' = yn * xd
    MUL25519    r14, r11, r12                   ; t = x' * y'
    MUL25519    r11, r11, r0                    ; x = x' * z'
    MUL25519    r12, r12, r0                    ; y = y' * z'
    MUL25519    r13, r0,  r0                    ; z = z' * z'
    RET
