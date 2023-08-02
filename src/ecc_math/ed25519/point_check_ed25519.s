; Check if point P is a valid Ed25519 point
;
;       (Y^2 - X^2)*Z^2 == Z^4 + d*X^2*Y^2 and
;               (X * Y) == (Z * T)
;
; Inputs:
;   Point P = (r7,  r8,  r9,  r10)
;
; Outputs:
;   Sets Z flag if point is valid
;
; Expects:
;   Ed25519 prime in r31
;   Ed25519 parameter d in r6

point_check_ed25519:
    MUL25519    r0,  r7,  r7    ; X^2
    MUL25519    r1,  r8,  r8    ; Y^2
    MUL25519    r2,  r9,  r9    ; Z^2
    SUBP        r3,  r1,  r0    ; (Y^2 - X^2)
    MUL25519    r3,  r3,  r2    ; (Y^2 - X^2)*Z^2

    MUL25519    r2,  r2,  r2    ; Z^4
    MUL25519    r0,  r0,  r6
    MUL25519    r0,  r0,  r1    ; d*X^2*Y^2
    ADDP        r0,  r0,  r2

    XOR         r3,  r3,  r0
    BRNZ        point_check_ed25519_ret
    MUL25519    r0,  r7,  r8        
    MUL25519    r3,  r9,  r10
    XOR         r3,  r3,  r0
point_check_ed25519_ret:
    RET
