; ==============================================================================
;  file    ops/clear.s
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
; Clears all GPRs, whole Data RAM In / Out, Initialize TMAC and SHA512 core.
;
; ==============================================================================

op_clear:
    MOVI    r31, 0

    CALL    clear_data_in
    CALL    clear_data_out
    CALL    clear_emem_out
    CALL    clear_regs

    HASH_IT
    TMAC_IT r0

    JMP     set_res_word
