; Square root ratio algorithm for GF(p) where p = 3 mod 4
; Follows algorithm [https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-16.html#appendix-F.2.1.2]
;
; Inputs:
;   u, v alements of GF(p) in r12, r16, where p = P-256 prime
;
; Outputs:
;   y in r10, where
;       y = sqrt(u / v) if (u / v) is square in GF(p), and
;       y = sqrt(-10 * (u / v)) otherwise.
;
;   Sets Z flag if (u / v)is square in GF(p)
;
; Expects:
;   NIST P-256 prime in r31
;
; Used registers:
;   r0...10
;
; Algorithm:
;
;           Constants:
;           1. c1 = (q - 3) / 4     # Integer arithmetic
;           2. c2 = sqrt(-Z)
;           
;           Procedure:
;           1. tv1 = v^2
;           2. tv2 = u * v
;           3. tv1 = tv1 * tv2
;           4. y1 = tv1^c1
;           5. y1 = y1 * tv2
;           6. y2 = y1 * c2
;           7. tv3 = y1^2
;           8. tv3 = tv3 * v
;           9. isQR = tv3 == u
;           10. y = CMOV(y2, y1, isQR)
;           11. return (isQR, y)

sqrt_ratio_3mod4:
; y1 -> r9
; y2 -> r10

    MUL256  r6,  r12,  r12
    ADDP    r7,  r16,  r12
    MUL256  r6,  r6,  r7

    MOV     r1,  r6
    CALL    inv_p256_c1
    MOV     r9,  r1

    MUL256  r9,  r9,  r7
    LD      r0,  ca_p256_c2
    MUL256  r10, r10, r0
    MUL256  r8,  r9,  r9
    MUL256  r8,  r8,  r12
    XOR     r0,  r8,  r16
    ZSWAP   r10, r9
    RET
