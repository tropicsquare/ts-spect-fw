; Compute y coordinate from x coordinate for Curve25519
; Solve y = sqrt(x*(x^2 + A*x + 1))
;
; This algorithm finds one of two possible y.
; It is used at the begining of X25519 algorithm.
;
; Inputs:
;   Affine coordinate x in r16
;
; Output:
;   Affine coordinate y in r17
;   Sets Zero flag, if y is valid (x*(x^2 + A*x + 1) is square)
;
; Expects:
;   Curve25519 prime in R31

get_y_curve25519:
    LD          r0,  ca_curve25519_a
    MUL25519    r0,  r0,  r16
    MUL25519    r1,  r16, r16
    ADDP        r1,  r1,  r0
    MOVI        r0,  1 
    ADDP        r1,  r1,  r0
    MUL25519    r1,  r1,  r16              ; r1 = x*(x^2 + A*x + 1)

    CALL        sqrt_p25519
    MOV         r17, r1
    MOVI        r2,  1
    NOT         r2,  r2
    AND         r2,  r0,  r2
    RET