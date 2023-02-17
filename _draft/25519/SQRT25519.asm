_SQRT25519
; input :
;   Y2[r12]
; output :
;   sqrt(Y2)[r13]
; used registers
;   {r0..3, r12, r13,r31}

    MOVI r0 0x002
    MUL25519 r2 r0 r12     ; r2 <- 2*Y2

;... bunch of multiplication to calculate r0 <- (2*Y2)^((p-5)/8) = v ...

    MUL25519 r1 r0 r0       ; r1 <- v^2
    MUL25519 r1 r2 r1      ; r1 <- 2*Y2*v^2 = i

    MOVI r3 0x001
    LD r31 0x....               ; r31 <- p_25519
    SUBP r1 r1 r3               ; r1 <- (i - 1)
    MUL25519 r13 r12 r0         ; r13 <- Y2 * v
    MUL25519 r13 r13 r1         ; r13 <- Y2 * v * (i - 1)

    RET



