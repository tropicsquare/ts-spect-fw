; Point Addition on curve Ed25519
; Input:
;               X    Y    Z    T
;   Point Q1 = (r7,  r8,  r9,  r10)
;   Point Q2 = (r11, r12, r13, r14)
; Output:
;   Q2 = Q1 + Q2
;
; Expects:
;   Ed25519 prime in r31
;   Ed25519 parameter d in r6
;
; Intermediate value registers:
;   r0-4

;   https://datatracker.ietf.org/doc/rfc8032/
;   
;      For point addition, the following method is recommended.  A point
;      (x,y) is represented in extended homogeneous coordinates (X, Y, Z,
;      T), with x = X/Z, y = Y/Z, x * y = T/Z.
;   
;      The neutral point is (0,1), or equivalently in extended homogeneous
;      coordinates (0, Z, Z, 0) for any non-zero Z.
;   
;                    A = (Y1-X1)*(Y2-X2)
;                    B = (Y1+X1)*(Y2+X2)
;                    C = T1*2*d*T2
;                    D = Z1*2*Z2
;                    E = B-A
;                    F = D-C
;                    G = D+C
;                    H = B+A
;                    X3 = E*F
;                    Y3 = G*H
;                    T3 = E*H
;                    Z3 = F*G

point_add_ed25519:
    SUBP        r0,  r8,  r7    ; r0 = Y1 - X1
    SUBP        r1,  r12, r11   ; r1 = Y2 - X2
    MUL25519    r0,  r0,  r1    ; r0 = r0 * r1  r0 = A

    ADDP        r1,  r8,  r7    ; r1 = Y1 + X1
    ADDP        r2,  r12, r11   ; r2 = Y2 + X2
    MUL25519    r1,  r1,  r2    ; r1 = r1 * r2  r1 = B

    MUL25519    r2,  r10, r14   ; r2 = T1 * T2
    MUL25519    r2,  r2,  r6    ; r2 = r2 * d
    ADDP        r2,  r2,  r2    ; r2 = r2 + r2  r2 = C

    MUL25519    r3,  r9,  r13   ; r3 = Z1 * Z2
    ADDP        r3,  r3,  r3    ; r3 = r3 + r3  r3 = D

    SUBP        r4,  r1,  r0    ; r4 = r1 - r0  r4 = E
    ADDP        r0,  r1,  r0    ; r0 = r1 + r0  r0 = H
    SUBP        r1,  r3,  r2    ; r1 = r3 - r2  r1 = F
    ADDP        r2,  r3,  r2    ; r2 = r3 + r2  r2 = G

    MUL25519    r11, r4,  r1    ; r11 = r4 * r1
    MUL25519    r13, r4,  r0    ; r13 = r4 * r0
    MUL25519    r12, r2,  r0    ; r12 = r2 * r0
    MUL25519    r14, r2,  r1    ; r14 = r2 * r1

    RET
