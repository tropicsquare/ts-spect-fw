_W25519toEd25519
; input :
;   point on W-25519 Pw[r14,15]
; output :
;   point on Ed25519 Ped[r10,11]
; used reisters :
;   {r0..4,r10,r11,r14,r15,r20,r21,r31}
    LD  r31 0x....
    CMPA r15 0x000
    BRZ YIsZero

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

    RET

_YIsZero
    MOVI r10 0
    MOVI r11 0
    MOVI r0 1
    SUBP r11 r11 r0

    RET