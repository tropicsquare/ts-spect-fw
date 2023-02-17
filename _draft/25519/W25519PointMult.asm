_W25519PointMult
; input :
;   s = [r30]
;   P = [r8,9]
; output :
;   Q[r14,15] = s * P
;   s = [r17]
; used registers :
;   {r0..17,r20,r21,r27..31}

; Compute Q = (bs1 * Q1) + (bs2 * Q2)
;           where Q1 + Q2 = P
;                 bs1 = rand1 * q_25519 + d
;                 bs2 = rand2 * q_25519 + d

    MOV r17 r30

; === Point Blinding ===

    GRV r10
    MUL25519 r8 r8 r10
    MUL25519 r9 r9 r10
    ; [r8,9,10] = Z-coord randomized P

    CALL W25519PointBlinding

; === PB done ===

    GRV r28
    LD r31 0x....   ; r31 <- q_25519
    SCB r29 r30 r28 ; [r30,29] = Blind(scalar, random, q_25519) = bs1

    ST r14 0x....
    ST r15 0x....
    ST r16 0x....

    CALL MontgomeryLadder25519 ; Q1[r8,9,10] <- bs1[r30,29] * P1[r11,12,13]
    ST r8  0x....
    ST r9  0x....
    ST r10 0x....   ; store Q1

    ; blind scalar second time for P2
    GRV r28
    MOV r30 r17
    LD r31 0x.... ;load q_25519
    SCB r29 r30 r28 ; [r30,29] = Blind(scalar, random, q_25519) = bs2

    LD r11 0x....
    LD r12 0x....
    LD r13 0x.... ; load previously stored P2 

    CALL MontgomeryLadder25519 ; Q2[r8,9,10] <- bs2[r30,29] * P2[r11,12,13]

    LD r11 0x....
    LD r12 0x....
    LD r13 0x.... ; load previosly stored Q1

    CALL W25519PointAdd ; Q[r14,15,16] <- Q2[r8,9,10] + Q1[r11,12,13]

    ; ToAffine(Q)
    MOV r20 r16
    CALL Inverse25519 ; r21 <- r20^(-1)
    MUL25519 r14 r14 r21
    MUL25519 r15 r15 r21

    RET