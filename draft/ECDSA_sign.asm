; ===============================
; =====     ECDSA sign      =====
; ===============================

    LD  r29 0x....
    LD  r30 0x....          ; [r30,29] <- 512 bit k ( result of KMAC256(w, h || n || z, 2*qlen, empty_string) )

    LD  r31 0x....          ; r31 <- q_256
    REDP r30 r30 r29

    CMPA r30 0x000
    BRZ ECDSAFail

    LD  r8 0x....
    LD  r9 0x....           ; P[r8,9] = B_256

    CALL W256PointMult

    LD  r31 0x....          ; r31 <- q_256
    MOVI r15 0
    REDP r14 r15 r14        ; r14 <- X mod q_256 = r

    CMPA r14 0x000
    BRZ ECDSAFail

    MOV r20 r17
    CALL Inverse256         ; r21 = k^(-1)

    LD r0 0x....            ; r0 = z (message)
    LD r1 0x....            ; r1 = d

    LD  r31 0x....          ; r31 <- q_256
    MULP r1 r1 r14          ; r1 = d * r
    ADDP r0 r0 r1           ; r0 = z + d * r
    MULP r1 r21 r0          ; r1 = k^(-1) * (z + d * r) = s

    ST r14 0x....
    ST r1  0x....

_ECDSASignDone
    MOVI r0 0x000 
    ST r0 0x....    
    END             ; success

_ECDSAFail
    MOVI r0 0x000 
    ST r0 0x....    
    END             ; fail