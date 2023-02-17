; ===============================
; =====        ECDH         =====
; ===============================

    LD r8 0x....            ; r8 <- x as little-endian
    ANDI r8 r8 0xF7F        ; clear MSB
    SWE r8 r8

    LD r0   0x....          ; r0 <- A
    LD r31  0x....          ; r31 <- p_25519
    ADDP r8 r8 r0

; compute y from x

    LD  r0 0x....           ;load W-25519.a from const. ROM
    LD  r1 0x....           ;load W-25519.b from const. ROM

    MUL25519 r3 r8 r8       ; r0 = x^2
    MUL25519 r3 r3 r8       ; r0 = x^3
    MUL25519 r2 r0 r8       ; r1 = a*x
    ADDP     r12 r2 r3      ; r12 = x^3 + a*x
    ADDP     r12 r9 r1      ; r12 = x^3 + a*x + b = Y2

    CALL IsSquare25519

    IS1 ECDH_Y2IsSquare

    CMPA r22 0x001
    BRZ ECDH_Y2IsSquare

    MOVI r0 0x000 
    ST r0 0x....    
    END             ; fail

_ECDH_Y2IsSquare

    CALL SQRT25519

    MOV r9 r13

    LD r30 0x....       ; r30 <- s (ECDH private key) or with GPK

    CALL W25519PointMult

    LD r0   0x....          ; r0 <- A
    LD r31  0x....          ; r31 <- p_25519
    ADDP r13 r13 r0

    ST r13 0x....

    MOVI r0 0x001 
    ST r0 0x....    
    END             ; success





