; Inputs:
;   chunk size in r11
;
; Outputs:
;   Pad mask in r5
;   first 1 bit position in r7
;   chunk size // 32 in r9

eddsa_e_pad_mask:
    ; prepare for padding bits mask
    MOVI        r6, 0
    NOT         r5, r6

    ANDI        r9,  r11, 0x60          ; Mask bits 5 and 6 (chunk size // 32)
    ANDI        r8,  r11, 0x1F          ; Mask bits 4:0 (chunk size mod 32)
    MOVI        r7,  32
    SUB         r8,  r7,  r8
    MOV         r7,  r8
    LSL         r7,  r7
    LSL         r7,  r7
    LSL         r7,  r7
    SUBI        r7,  r7,  1             ; position of the '1' at the start of padding

eddsa_e__pad_mask_loop:
    ROLIN       r5,  r5,  r6
    SUBI        r8,  r8,  1
    BRNZ        eddsa_e__pad_mask_loop

    RET