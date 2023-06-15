; Input: u, an element of GF(2^255-19).
; Output: (xn, xd, yn, yd) such that (xn / xd, yn / yd) is a point on curve25519.
;         return (r3, r7, r11, r8) = (xn, xd, y, 1)

map_to_curve_elligator2_curve25519:
; r0    u, y2
; r1    y1, -y
; r2    x2n, y
; r3    y21, xn
; r4    y22
; r6    tv1, gx2
; r7    xd
; r8    gx1
; r9    x1n
; r10   tv2
; r11   gxd
; r12   rv3
; r13   y11
; r14   y12

    MUL25519    r6,  r0,  r0            ; tv1 = pow(u, 2, p)
    ADDP        r6,  r6,  r6            ; tv1 = 2 * tv1 % p
    MOVI        r30, 0x001
    ADDP        r7,  r6,  r30           ; xd = tv1 + 1 % p          Nonzero: -1 is square (mod p), tv1 is not
    CMPA        r7,  0                  ; If xd == 0, the resulting point is point at infinity -> 
    BRZ         curve25519_point_generate_y_final
    LD          r8,  ca_curve25519_a
    MOVI        r30, 0x000
    SUBP        r9,  r30, r8            ; x1n = -A  % p             x1 = x1n / xd = -A / (1 + 2 * u^2)
    MUL25519    r8,  r8,  r6            ; gx1 = A * tv1  % p        x1n + A * xd
    MUL25519    r10, r7,  r7            ; tv2 = pow(xd, 2, p)
    MUL25519    r11, r10, r7            ; gxd = tv2 * xd  % p       gxd = xd^3
    MUL25519    r8,  r8,  r9            ; gx1 = gx1 * x1n  % p      x1n^2 + A * x1n * xd
    ADDP        r8,  r8,  r10           ; gx1 = gx1 + tv2  % p      x1n^2 + A * x1n * xd + xd^2
    MUL25519    r8,  r8,  r9            ; gx1 = gx1 * x1n  % p      x1n^3 + A * x1n^2 * xd + x1n * xd^2
    MUL25519    r12, r11, r11           ; tv3 = pow(gxd, 2, p)
    MUL25519    r10, r12, r12           ; tv2 = pow(tv3, 2, p)      gxd^4
    MUL25519    r12, r12, r11           ; tv3 = tv3 * gxd % p       gxd^3
    MUL25519    r12, r12, r8            ; tv3 = tv3 * gx1 % p       gx1 * gxd^3
    MUL25519    r10, r10, r12           ; tv2 = tv2 * tv3 % p       gx1 * gxd^7

    MOV         r1,  r10
    CALL        inv_p25519_250          ; r1 = pow(tv2, 2^250-1, p)
    MUL25519    r2,  r2,  r2 
    MUL25519    r2,  r2,  r2 
    MUL25519    r13, r2,  r10           ; y11 = pow(tv2, c4, p)     (gx1 * gxd^7)^((p - 5) / 8)

    MUL25519    r13, r13, r12           ; y11 = y11 * tv3  % p      gx1 * gxd^3 * (gx1 * gxd^7)^((p - 5) / 8)
    LD          r30, ca_pg_curve25519_c3
    MUL25519    r14, r13, r30           ; y12 = y11 * c3  % p
    MUL25519    r10, r13, r13           ; tv2 = pow(y11, 2, p)
    MUL25519    r10, r10, r11           ; tv2 = tv2 * gxd  % p

    SUBP        r4,  r10, r8            ; e1 = tv2 == gx1
                                        ; y1 = cmov(y12, y11, e1)   If g(x1) is square, this is its sqrt
    CMPA        r4,  0                  
    BRNZ        curve25519_point_generate_y1_y12
curve25519_point_generate_y1_y11:
    MOV         r1, r13
    JMP         curve25519_point_generate_y1_next
curve25519_point_generate_y1_y12:
    MOV         r1, r14
    JMP         curve25519_point_generate_y1_next
curve25519_point_generate_y1_next:

    MUL25519    r2,  r9,  r6            ; x2n = x1n * tv1  % p      x2 = x2n / xd = 2 * u^2 * x1n / xd
    MUL25519    r3,  r13, r0            ; y21 = y11 * u  % p

    ORI         r4,  r30, 0x001         ; r4 = c2
    MUL25519    r3,  r3,  r4            ; y21 = y21 * c2 % p
    MUL25519    r4,  r3,  r30           ; y22 = y21 * c3 % p
    MUL25519    r6,  r8,  r6            ; gx2 = gx1 * tv1  % p      g(x2) = gx2 / gxd = 2 * u^2 * g(x1)
    MUL25519    r10, r3,  r3            ; tv2 = pow(y21, 2, p)
    MUL25519    r10, r10, r11           ; tv2 = tv2 * gxd % p

    SUBP        r30, r10, r6            ; e2 = tv2 == gx2
                                        ; y2 = cmov(y22, y21, e2)   If g(x2) is square, this is its sqrt
    CMPA        r30, 0
    BRNZ        curve25519_point_generate_y2_y22
curve25519_point_generate_y2_y21:
    MOV         r0, r3
    JMP         curve25519_point_generate_y2_next
curve25519_point_generate_y2_y22:
    MOV         r0, r4
    JMP         curve25519_point_generate_y2_next
curve25519_point_generate_y2_next:

    MUL25519    r10, r1,  r1            ; tv2 = pow(y1, 2, p)
    MUL25519    r10, r10, r11           ; tv2 = tv2 * gxd % p

    SUBP        r30, r10, r8,           ; e3 = tv2 == gx1
                                        ; xn = cmov(x2n, x1n, e3)   If e3, x = x1, else x = x2
    CMPA        r30, 0
    BRNZ        curve25519_point_generate_xn_x2n
curve25519_point_generate_xn_x1n:
    MOV         r3, r9
    JMP         curve25519_point_generate_xn_next
curve25519_point_generate_xn_x2n:
    MOV         r3, r2
    JMP         curve25519_point_generate_xn_next
curve25519_point_generate_xn_next:
                                        ; y = cmov(y2, y1, e3)      If e3, y = y1, else y = y2
BRNZ        curve25519_point_generate_y_y2
curve25519_point_generate_y_y1:
    MOV         r2,  r1
    MOVI        r30, 0x001 
    JMP         curve25519_point_generate_y_next
curve25519_point_generate_y_y2:
    MOV         r2, r0
    MOVI        r30, 0x000
    JMP         curve25519_point_generate_y_next
curve25519_point_generate_y_next:
            
    MOVI            r0,  0x000
    SUBP            r1,  r0,  r2            ; r1 = -y
    MOVI            r8,  0x001
    AND             r6,  r2,  r8            ; e4 = sgn0(y) == 1         Fix sign of y
    XOR             r30, r30, r6
                                            ; y = cmov(y, -y, e3 ^ e4)
    BRZ         curve25519_point_generate_y_plus
curve25519_point_generate_y_minus:
    MOV         r11, r1
    JMP         curve25519_point_generate_y_final
curve25519_point_generate_y_plus:
    MOV         r11, r2
    JMP         curve25519_point_generate_y_final
curve25519_point_generate_y_final:
    RET