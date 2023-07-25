; Map to curve algorithm using Simplified Shallue-van de Woestijne-Ulas method
; [https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-16.html#section-6.6.2]
; 
; Input:
;   u, an element of GF(p256) in r0
;
; Output:
;   Point on curve P-256 in projective coordinates (x, y, z) in (r17, r18, r19)
;
; Expects:
;   P-256 prime in r31
;
; Algorithm:
;
;                   1.  tv1 = u^2
;                   2.  tv1 = Z * tv1
;                   3.  tv2 = tv1^2
;                   4.  tv2 = tv2 + tv1
;                   5.  tv3 = tv2 + 1
;                   6.  tv3 = B * tv3
;                   7.  tv4 = CMOV(Z, -tv2, tv2 != 0)
;                   8.  tv4 = A * tv4
;                   9.  tv2 = tv3^2
;                   10. tv6 = tv4^2
;                   11. tv5 = A * tv6
;                   12. tv2 = tv2 + tv5
;                   13. tv2 = tv2 * tv3
;                   14. tv6 = tv6 * tv4
;                   15. tv5 = B * tv6
;                   16. tv2 = tv2 + tv5
;                   17.   x = tv1 * tv3
;                   18. (is_gx1_square, y1) = sqrt_ratio(tv2, tv6)
;                   19.   y = tv1 * u
;                   20.   y = y * y1
;                   21.   x = CMOV(x, tv3, is_gx1_square)
;                   22.   y = CMOV(y, y1, is_gx1_square)
;                   23.  e1 = sgn0(u) == sgn0(y)
;                   24.   y = CMOV(-y, y, e1)
;                   25.   y = y * tv4
;                   26. return (x, y, tv4)

map_to_curve_simple_swu:
    MOV     r20, r0
    LD      r0,  ca_p256_Z
    LD      r1,  ca_p256_a
    LD      r2,  ca_p256_b

    MUL256  r11, r20, r20
    MUL256  r11, r0,  r11
    MUL256  r12, r11, r11
    ADDP    r12, r12, r11
    MOVI    r4,  1
    ADDP    r13, r12, r4
    MUL256  r13, r2,  r13

    ; r14 = cmov(r0, (-r12), r12 != 0)
    MOVI    r4,  0
    SUBP    r14, r4,  r12
    XORI    r0,  r12, 0
    ZSWAP   r0,  r14

    MUL256  r14, r1,  r14
    MUL256  r12, r13, r13
    MUL256  r16, r14, r14
    MUL256  r15, r1,  r16
    ADDP    r12, r12, r15
    MUL256  r12, r12, r13
    MUL256  r16, r16, r14
    MUL256  r15, r2,  r16
    ADDP    r12, r12, r15
    MUL256  r17, r11, r13

    ; is_gx1_square, y1 = sqrt_ratio_3mod4(r12, r16)
    CALL    sqrt_ratio_3mod4

    MUL256  r18, r11, r20
    MUL256  r18, r18, r10

    ; r17 = cmov(r17, r13, is_gx1_square)
    ZSWAP   r17, r13

    ; r18 = cmov(r18, r10, is_gx1_square)
    ZSWAP   r18, r10

    MOVI    r1,  0
    SUBP    r1,  r1,  r18
    ; e1 = sgn0(r20) == sgn0(r18)
    XOR     r0,  r20, r18
    ANDI    r0,  r0,  1

    ; r18 = cmov(r1, r18, e1)
    ZSWAP   r18, r0
    MOV     r18, r0
    MUL256  r18, r18, r14
    MOV     r19, r14

    RET
