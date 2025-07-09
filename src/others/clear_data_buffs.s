; ==============================================================================
;  file    other/clear_data_buffs.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
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
    MOVI    r6,  0x200
    MOVI    r2,  0x10
    ROL8    r2,  r2
clear_data_out_loop:
    OR      r3,  r6,  r2
    SUBI    r6,  r6,  32
    STR     r31, r3
    BRNZ    clear_data_out_loop

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

    RET

clear_regs:
    MOVI    r0,  0
    MOVI    r1,  0
    MOVI    r2,  0
    MOVI    r3,  0
    MOVI    r4,  0
    MOVI    r5,  0
    MOVI    r6,  0
    MOVI    r7,  0
    MOVI    r8,  0
    MOVI    r9,  0
    MOVI    r10, 0
    MOVI    r11, 0
    MOVI    r12, 0
    MOVI    r13, 0
    MOVI    r14, 0
    MOVI    r15, 0
    MOVI    r16, 0
    MOVI    r17, 0
    MOVI    r18, 0
    MOVI    r19, 0
    MOVI    r20, 0
    MOVI    r21, 0
    MOVI    r22, 0
    MOVI    r23, 0
    MOVI    r24, 0
    MOVI    r25, 0
    MOVI    r26, 0
    MOVI    r27, 0
    MOVI    r28, 0
    MOVI    r29, 0
    MOVI    r30, 0
    MOVI    r31, 0

    RET
