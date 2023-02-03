_MontgomeryLadder25519
; input :
;   bs[r30,r29]
;   P[r11,r12,r13]
; output :
;   Q[r8,r9,r10]
; used registers : 
;   {r0..16,r27..31}

    MOVI r8, 0x000
    MOVI r9, 0x001
    MOVI r10, 0x000 ;Q = [r8,9,10]

    ;clear C flag
    ROR r10 r10;

    LD r31 0x....       ;load to r31 p_25519 from const. ROM

    MOVI r27 256
    MOVI r28 2

_ML25519Loop
    SUBI r27 r27 1

    BRNZ ML25519InnerLoopNotDone
        SUBI r28 r28 1
        BRZ ML25519Done
        MOVI r27 256

_ML25519InnerLoopNotDone
        CPI r28 2
        BRZ ML25519LoopFirstHalf
            ROL r29 r29
            JMP ML25519Main

_ML25519LoopFirstHalf
            ROL r30 r30

_ML25519Main
        CSWAP r11 r8
        CSWAP r12 r9
        CSWAP r13 r10

        CALL W25519PointAdd ; tmp[r14,15,16] <- Q[r8,9,10] + P[r11,12,13]
        MOV r11 r14
        MOV r12 r15
        MOV r13 r16

        CALL W25519PointDub ; tmp[r14,15,16] <- 2 * Q[r8,9,10]
        MOV r8  r14
        MOV r9  r15
        MOV r10 r16

        CSWAP r11 r8
        CSWAP r12 r9
        CSWAP r13 r10

        JMP ML25519Loop
_ML25519Done
    RET