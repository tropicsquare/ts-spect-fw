; ==============================================================================
;  file    other/clear_data_buffs.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Clears all data buffers:
;   - Data RAM In
;   - Data RAM Out
;   - EMEM Out
;
; ==============================================================================

clear_data_in:
    MOVI    r6,  0x800
clear_data_in_loop:
    SUBI    r6,  r6,  32
    STR     r31, r6
    BRNZ    clear_data_in_loop

    RET

clear_data_out:
    MOVI    r6,  0x1E0
    MOVI    r2,  0x10
    ROL8    r2,  r2
clear_data_out_loop:
    OR      r3,  r6,  r2
    SUBI    r6,  r6,  32
    STR     r31, r3
    BRNZ    clear_data_out_loop
    ST      r31, 0x1000

    RET

clear_emem_out:
    MOVI    r6,  0x80
    MOVI    r2,  0x50
    ROL8    r2,  r2
clear_emem_out_loop:
    OR      r3,  r6,  r2
    SUBI    r6,  r6,  32
    STR     r31, r3
    BRNZ    clear_emem_out_loop
    ST      r31, 0x5000

    RET

clear_regs:
    MOV     r0,  r31
    MOV     r1,  r31
clear_regs_before_return:
    MOV     r2,  r31
    MOV     r3,  r31
    MOV     r4,  r31
    MOV     r5,  r31
    MOV     r6,  r31
    MOV     r7,  r31
    MOV     r8,  r31
    MOV     r9,  r31
    MOV     r10, r31
    MOV     r11, r31
    MOV     r12, r31
    MOV     r13, r31
    MOV     r14, r31
    MOV     r15, r31
    MOV     r16, r31
    MOV     r17, r31
    MOV     r18, r31
    MOV     r19, r31
    MOV     r20, r31
    MOV     r21, r31
    MOV     r22, r31
    MOV     r23, r31
    MOV     r24, r31
    MOV     r25, r31
    MOV     r26, r31
    MOV     r27, r31
    MOV     r28, r31
    MOV     r29, r31
    MOV     r30, r31

    RET
