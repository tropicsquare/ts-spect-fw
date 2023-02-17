_W256PointBlinding
    ; input :
    ;   Point to blind P[r8,9,10]
    ; output :
    ;   P1[r11,12,13]
    ;   P2[r14,15,16]
    ; used registers :
    ;   {r0...16,r31}


    GRV r11             ;let X = r11
    LD  r15 0x....      ;load W-256.a from const. ROM
    LD  r16 0x....      ;load W-256.b from const. ROM
    LD  r31 0x....      ;load to r31 p_256 from const. ROM

    MUL256 r0 r11 r11       ; r0 = x^2
    MUL256 r0 r0 r11        ; r0 = x^3
    MUL256 r1 r15 r11       ; r1 = a*x
    ADDP     r12 r0 r1      ; r12 = x^3 + a*x
    ADDP     r12 r12 r16    ; r12 = x^3 + a*x + b = Y2

    CALL IsSquare256

    CMPA r13 0x000
    BRZ PB255_Y2IsSquare

    ; do something ???

PB256_Y2IsSquare

    CALL SQRT256

    MOV r12 r13        ; P1[X,Y] = [r11,r12]

    ; ... make P1 negative to [r11,r12] ...

    GRV r13
    MUL25519 r11 r11 r13
    MUL25519 r12 r12 r13    ;[r11,12,13] = Z-coord randomized -P1

    CALL W25519PointAdd ; P2[r14,15,16] <- P[r8,9,10] + -P1[r11,12,13]

    ; ... repare -P1 to +P1 to [r11,12,13] ...

    RET

