op_x25519_end:
    MOVI    r1, 32
    JMP     set_res_word

op_x25519_key_fail:
    MOVI    r0,  ret_key_err
    JMP     op_x25519_end

; ======================================================
;   x25519_kpair_gen
; ======================================================
op_x25519_kpair_gen:
    GRV     r19
    MOVI    r0,  7
    MOVI    r1,  255
    SBIT    r0,  r0, r1
    NOT     r0,  r0
    AND     r19, r0, r19
    MOVI    r1,  254
    SBIT    r19, r19, r1

    ST      r19, x25519_context_etpriv

    MOVI    r16, 9
    MOVI    r20, 0xD3

    CALL    x25519_full_masked

    CMPI    r0,  0
    BRNZ    op_x25519_end
    ST      r11, x25519_kpair_gen_output_etpub
    JMP     op_x25519_end

; ======================================================
;   x25519_sc_et_eh
; ======================================================
op_x25519_sc_et_eh:
    LD      r19, x25519_context_etpriv
    LD      r16, x25519_sc_et_eh_input_ehpub
    ST      r16, x25519_context_ehpub

    MOVI    r20, 0xD4

    CALL    x25519_full_masked

    CMPI    r0,  0
    BRNZ    op_x25519_end
    ST      r11, x25519_sc_et_eh_output_x1
    JMP     op_x25519_end

; ======================================================
;   x25519_sc_et_sh
; ======================================================
op_x25519_sc_et_sh:
    LD      r1, x25519_sc_et_sh_input_slot
    LDK     r16, r1, 0x200
    BRE     op_x25519_key_fail
    KBO     r1, 0x205
    BRE     op_x25519_key_fail

    LD      r19, x25519_context_etpriv

    MOVI    r20, 0xD5

    CALL    x25519_full_masked

    CMPI    r0,  0
    BRNZ    op_x25519_end
    ST      r11, x25519_sc_et_sh_output_r2
    JMP     op_x25519_end

; ======================================================
;   x25519_sc_st_eh
; ======================================================
op_x25519_sc_st_eh:
    LD      r16, x25519_context_ehpub
    MOVI    r1, 0
    LDK     r19, r1, 0x000
    BRE     op_x25519_key_fail
    KBO     r1, 0x005
    BRE     op_x25519_key_fail

    MOVI    r0,  7
    MOVI    r1,  255
    SBIT    r0,  r0, r1
    NOT     r0,  r0
    AND     r19, r0, r19
    MOVI    r1,  254
    SBIT    r19, r19, r1

    MOVI    r20, 0xD6

    CALL    x25519_full_masked

    CMPI    r0,  0
    BRNZ    op_x25519_end
    ST      r11, x25519_sc_st_eh_output_r3
    JMP     op_x25519_end

