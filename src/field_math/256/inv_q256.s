; Inversion modulo q256
; input Z in register r1
; output z^(-1) mod q256 in register r1
; used registers : r1-x

inv_q256:
    MULP r2, r1, r1   ; e = 2
    MULP r3, r2, r1   ; e = 3

    MULP r4, r3, r3
    MULP r4, r4, r4
    MULP r5, r4, r3   ; e = f

    MULP r4, r5, r5
    MULP r4, r4, r4
    MULP r4, r4, r4
    MULP r4, r4, r4
    MULP r5, r4, r5   ; e = ff

    MULP r4, r5, r5
    MULP r4, r4, r4
    MOVI r30, 6
inv_q256_loop_8:
    MULP r4, r4, r4
    MULP r4, r4, r4
    MULP r4, r4, r4
    SUBI r30, r30, 3
    BRNZ inv_q256_loop_8

    MULP r5, r4, r5   ; e = ffff

    MULP r4, r5, r5
    MOVI r30, 15
inv_q256_loop_16:
    MULP r4, r4, r4
    MULP r4, r4, r4
    MULP r4, r4, r4
    SUBI r30, r30, 3
    BRNZ inv_q256_loop_16

    MULP r6, r4, r5   ; e = ffffffff

    MULP r4, r6, r6
    MOVI r30, 63
inv_q256_loop_64:
    MULP r4, r4, r4
    MULP r4, r4, r4
    MULP r4, r4, r4
    SUBI r30, r30, 3
    BRNZ inv_q256_loop_64

    MULP r5, r4, r6   ; e = ffffffff 00000000 ffffffff

    MULP r4, r5, r5
    MULP r4, r4, r4
    MOVI r30, 30
inv_q256_loop_32:
    MULP r4, r4, r4
    MULP r4, r4, r4
    MULP r4, r4, r4
    SUBI r30, r30, 3
    BRNZ inv_q256_loop_32

    MULP r4, r4, r6   ; e = ffffffff 00000000 ffffffff ffffffff

    LD r5, ca_ecdsa_exp_low
    MOVI r30, 128
inv_q256_loop_lowpart:
    ; make 00 space
    MULP r4, r4, r4
    MULP r4, r4, r4
    ; check first bit
    LSL r5, r5
    BRC inv_q256_loop_x1

inv_q256_loop_x0:
    ; check second bit
    LSL r5, r5
    BRNC inv_q256_loop_lowpart_back
inv_q256_loop_x01:
    ; chunk = 01
    MULP r4, r4, r1
    JMP inv_q256_loop_lowpart_back

inv_q256_loop_x1:
    ; check second bit
    LSL r5, r5
    BRC inv_q256_loop_x11
inv_q256_loop_x10:
    ; chunk = 10
    MULP r4, r4, r2
    JMP inv_q256_loop_lowpart_back
inv_q256_loop_x11:
    ; chunk = 11
    MULP r4, r4, r3

inv_q256_loop_lowpart_back:
    SUBI r30, r30, 2
    BRNZ inv_q256_loop_lowpart

    MOV r1, r4
    RET
    