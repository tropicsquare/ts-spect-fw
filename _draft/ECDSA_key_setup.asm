; get private key (seed)
1) LD   r30 0x....  ;for key loaded by user
   ST   r30 0x....  ; MemOut[....] <- d

2)  GRV  r29         ;for key generated internaly by SPECT
    GRV  r30
    LD   r31 0x....  ; r31 <- q_256
    REDP r30 r29 r30 ; r30 = d = 512bit-random mod q_256
    ST   r30 0x....  ; MemOut[....] <- d

    LD r8 0x....
    LD r9 0x....    ; load B_256 to [r8,9]

    CALL W256PointMult ; Q[r14,15] = d * B_256[r8,9]

; =======================================

_ECDSAKeySetupDone
    ST r14 0x....
    ST r15 0x....
    
    MOVI r0 0x000 
    ST r0 0x....    
    END             ; success