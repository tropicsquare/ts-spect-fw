_W25519PointBlinding
; input
;   P[r8,9,10]
; output
;   P1[r11,12,13]
;   P2[r14,15,16]
; used registers
;   {r0...r16, r21...23,r32}

    GRV r11             ;let X = r11
    LD  r15 0x....      ;load W-25519.a from const. ROM
    LD  r16 0x....      ;load W-25519.b from const. ROM
    LD  r31 0x....      ;load to r31 p_25519 from const. ROM

    MUL25519 r0 r11 r11     ; r0 = x^2
    MUL25519 r0 r0 r11      ; r0 = x^3
    MUL25519 r1 r15 r11     ; r1 = a*x
    ADDP     r12 r0 r1      ; r12 = x^3 + a*x
    ADDP     r12 r12 r16    ; r12 = x^3 + a*x + b = Y2

    ; check if Y2 is a square in GF(p_25519)
    CALL IsSquare25519

    CMPA r13 0x001
    BRZ PB25519_Y2IsSquare

    ; do something ??

_PB25519_Y2IsSquare
    
    CALL SQRT25519

    MOV r21 r11
    MOV r22 r12
    GRV r23
    MUL25519 r21 r21 r23
    MUL25519 r22 r22 r23

    ; P1[r21,22,23]

    GRV r10
    MUL25519 r8 r8 r10
    MUL25519 r9 r9 r10  ; [r8,9,10] = Z-coord randomized ToW25519(B_25519)

    ;... make P1 negative to [r11,r12,r13] ...

    CALL W25519PointAdd ; P2[r14,15,16] <- B[r8,9,10] + -P1[r11,12,13]

    MOV r11 r21
    MOV r12 r22
    MOV r13 r23

    RET