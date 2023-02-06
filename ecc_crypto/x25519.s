; X25519 function
; input k -> 0x0020
; input u -> 0x0000
; output u -> 0x1000

x25519_calculation:
    CSWAP r11, r13
    CSWAP r12, r14

    ADDP        r1,  r11, r12   ; r1 = a
    MUL25519    r2,  r1,  r1    ; r2 = aa
    SUBP        r3,  r11, r12   ; r3 = b
    MUL25519    r4,  r3,  r3    ; r4 = bb
    SUBP        r5,  r2,  r4    ; r5 = e
    ADDP        r6,  r13, r14   ; r6 = c
    SUBP        r7,  r13, r14   ; r7 = d
    MUL25519    r8,  r7,  r1    ; r8 = da
    MUL25519    r9,  r6,  r3    ; r9 = cb
    ADDP        r13, r8,  r9
    MUL25519    r13, r13, r13
    SUBP        r14, r8,  r9
    MUL25519    r14, r14, r14
    MUL25519    r14, r10, r14
    MUL25519    r11, r2,  r4
    LD          r1, c_a24_addr
    MUL25519    r12, r1,  r5
    ADDP        r12, r2,  r12
    MUL25519    r12, r5,  r12

    CSWAP r11, r13
    CSWAP r12, r14

    RET

x25519:
    LD r10, c_u_in
    LD r28, c_key
    
    ANDI R28, r28, 0xF7F
    ORI R28, r28, 0x040
    SWE r28, r28
    ANDI r28, r28, 0xFF8
    
    LD r31, c_q25519_8_addr
    LD r3, c_rng
    SCB r28, r28, r3

    SWE r10, r10        ; r10 = x1
    MOVI r11, 1         ; r11 = x2
    MOVI r12, 0         ; r12 = z2
    MOV r13, r10        ; r13 = x3
    MOVI r14, 1         ; r14 = z3

    LD r31, c_p25519_addr

    MOVI r30, 256
x25519_loop_512_256:
    ROL r29, r29
    CALL x25519_calculation
    SUBI r30, r30, 1
    BRNZ x25519_loop_512_256

    MOVI r30, 256
x25519_loop_255_0:
    ROL r28, r28
    CALL x25519_calculation
    SUBI r30, r30, 1
    BRNZ x25519_loop_255_0

    MOV r1, r12
    CALL inv_p25519
    
    MUL25519 r10, r11, r1
    SWE r10, r10
    ST r10, c_u_out
    RET
