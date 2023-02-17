; get private key (seed)
1) LD r30 0x....    ;for key loaded by user
2) GRV r30          ;for key generated internaly by SPECT

    ;make nonce
    HASH_IT
    MOVI r29 1
    ROR r29 r29
    MOVI r28 0
    MOVI r27 256
    HASH r30 r31 r27    ;SHA-512(r30|r29|r28|r27)
                        ;        seed | 10..0 | 0..0 | 256

    ;store prefix 
    ST r31 0x....

    ;r30 is vector of 32 octets, r30[255:247] = octet_1 ... r30[7:0] = octet_32
    ;switch endianity of r30, so r30[255:247] = octet_32 ... r30[7:0] = octet_1
    SWE  r30 r30
    ROL8 r30 r30
    ANDI r30 r30 0x87F
    ORI  r30 r30 0x040
    ROR8 r30 r30

    ;store the scalar s in r30 
    ST r30 0x....

    ;blind scalar s in r30
    GRV r28
    LD  r31 0x....      ; load to r31 q_25519 from const. ROM
    SCB r29 r30 r28     ; [r30,r29] <- Blind(scalar, random, q_25519)

    LD  r8 0x....      ;load X-coordinate of ToW25519(B_25519) from const. ROM
    LD  r9 0x....      ;load Y-coordinate of ToW25519(B_25519) from const. ROM

    CALL W25519PointBlinding

    ; now we have first blinded 512 bit scalar in [r30,r29] and two points P2[r14,15,16], P1[r11,12,13], P1 + P2 = ToW25519(B_25519)
    ST r14 0x....
    ST r15 0x....
    ST r16 0x....

    CALL MontgomeryLadder25519 ; Q1[r8,9,10] <- bs[r30,29] * P1[r11,12,13]
    ST r8  0x....
    ST r9  0x....
    ST r10 0x....

    ; blind scalar second time for P2
    GRV r28
    LD r30 0x.... ;load previosly stored secret scalar to r30
    LD r31 0x.... ;load q_25519
    SCB r29 r30 r28 

    LD r11 0x....
    LD r12 0x....
    LD r13 0x....

    CALL MontgomeryLadder25519 ; Q2[r8,9,10] <- bs[r30,29] * P2[r11,12,13]

    LD r11 0x....
    LD r12 0x....
    LD r13 0x....

    CALL W25519PointAdd ; Q[r14,15,16] <- Q2[r8,9,10] + Q1[r11,12,13]

; ToAffine(Q)
    MOV r20 r16
    CALL Inverse25519 ; r21 <- r20^(-1)
    MUL25519 r14 r14 r21
    MUL25519 r15 r15 r21

; FromWeiToEdw(Q)
    LD   r31 0x....
    IS0 r15 YIsZero
    LD  r1 0x....   ; r1 = A
    LD  r2 0x....   ; r2 = B

    SUBP r0 r14 r1      ; r0 = x - A
    MUL25519 r10 r0 r2
    MOV r20 r15
    CALL Inverse25519
    MUL25519 r10 r21    ; r10 = A(X)

    MOVI r3 1
    SUBP r4 r0 r3
    ADDP r20 r0 r3
    CALL Inverse25519
    MUL25519 r11 r4 r21 ; r11 = A(Y)

    JMP EdDSAKeySetupDone

_YIsZero
    MOVI r10 0
    MOVI r11 0
    MOVI r16 1
    SUBP r11 r11 r16

_EdDSAKeySetupDone
    ST r10 0x....
    ST r11 0x....
    
    MOVI r0 0x000 
    ST r0 0x....    
    END             ; success
