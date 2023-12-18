; ==============================================================================
;  file    ops/sha512_ops.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE.txt file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
; ==============================================================================
;
; SHA512 Ops
;   - Init
;   - Update
;   - Final
;
; ==============================================================================
sha512_one_block:
    SWE r3, r3
    SWE r2, r2
    SWE r1, r1
    SWE r0, r0

    HASH r4, r0
    RET
op_sha512_init:
    HASH_IT
    MOVI r0, ret_op_success
    MOVI r1, 0
    MOVI r30, sha512_init_id
    JMP set_res_word

op_sha512_update:
    LD r3, sha512_input_data0
    LD r2, sha512_input_data1
    LD r1, sha512_input_data2
    LD r0, sha512_input_data3
    CALL sha512_one_block
    MOVI r0, ret_op_success
    MOVI r1, 0
    MOVI r30, sha512_update_id
    JMP set_res_word

op_sha512_final:
    LD r3, sha512_input_data0
    LD r2, sha512_input_data1
    LD r1, sha512_input_data2
    LD r0, sha512_input_data3
    CALL sha512_one_block
    SWE r4, r4
    SWE r5, r5
    ST r5, sha512_final_output_digest0
    ST r4, sha512_final_output_digest1
    HASH_IT
    MOVI r0, ret_op_success
    MOVI r1, 64
    MOVI r30, sha512_final_id
    JMP set_res_word