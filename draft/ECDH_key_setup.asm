; ===============================
; =====   ECDH key setup    =====
; ===============================

1) LD r30 0x....        ; if scalar is loaded by user
2) GRV r30              ; if scalar is generated internally by SPECT

    LD r8 0x....        
    LD r9 0x....        ; [r8,9] <- BasePoint B converted to W-25519

    CALL W25519PointMult

    LD r0   0x....          ; r0 <- A
    LD r31  0x....          ; r31 <- p_25519
    ADDP r13 r13 r0

    ST r13 0x....
    ST r17 0x....

    MOVI r0 0x000 
    ST r0 0x....    
    END             ; success