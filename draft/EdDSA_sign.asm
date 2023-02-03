; ===============================
; =====     EdDSA sign      =====
; ===============================

; get r
    LD  r29 0x....
    LD  r30 0x....          ; [r30,29] <- 512 bit k ( result of KMAC256(w, h || n || z, 2*qlen, empty_string) )
    ; can be done by GPK also

; let r = r mod q
    LD  r31 0x....          ; r31 <- q_25519
    REDP r30 r30 r29        ; r30 = r

; compute R = r * B
    LD  r8 0x....
    LD  r9 0x....           ; P[r8,9] = ToW25519(B_Ed25519)  

    CALL W25519PointMult    ; Rw[r14,15] = r * ToW25519(B_Ed25519)
    CALL W25519toEd25519    ; R[r10,11]

; ENC(R) is encoding of point R
    CALL EdDSAPointEncode   ; ENC(R)[r12]

; compute e = SHA-512(ENC(R) || A || M)
    ; note : message M is optional length,
    ; so it shall be divided into 256 bit blocks and provided by external system
    ; by chunks of at least 4 blocks (except end of message)
    MOV r0 r12              ; r0 = ENC(R)
    LD r1  0x....           ; r1 = A
    LD r2  0x....           ; r2 = 256-bit part of message
    LD r3  0x....           ; r3 = 256-bit part of message

    LD r4  0x....           ; r4 = message length (in 256bit message blocks)

; ... how to stream the message ??? ....
    
    SWE r30 r30
    SWE r29 r29
    ; e[r29,30]

; compute S = (r + e*s)
    LD r31 0x....           ; r31 <- q_25519
    REDP r30 r29 r30
    
    LD r0 0x....            ; r0 <- s
    MULP r0 r0 r30
    ADDP r0 r0 r17

_EdDSASignDone
    ST r17 0x....
    ST r0 0x....
    
    MOVI r0 0x000 
    ST r0 0x....    
    END             ; success
    