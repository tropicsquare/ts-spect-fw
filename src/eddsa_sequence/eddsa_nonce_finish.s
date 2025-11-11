; ==============================================================================
;  file    eddsa_sequence/eddsa_nonce_finish.s
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
; Finish EdDSA deterministic nonce derivation.
; Process the last chunk of the message with TMAC
;
; ==============================================================================

op_eddsa_nonce_finish:
    ; Check and update OP Link context
    LD          r1,  ca_op_link
    CMPI        r1,  eddsa_nonce_init_id
    BRZ         eddsa_nonce_finish_ctx_ok
    CMPI        r1,  eddsa_nonce_update_id
    BRNZ        eddsa_ctx_fail

eddsa_nonce_finish_ctx_ok:
    MOVI        r1,  eddsa_nonce_finish_id
    ST          r1,  ca_op_link

    CALL        get_data_in_size
    MOV         r11, r0                         ; number of bytes in the last chunk

    CALL        eddsa_nonce_load_msg

    MOVI        r15, 0x80
    ROL8        r15, r15
    ROL8        r15, r15
    ROL8        r15, r15

eddsa_nonce_finish_loop_l1:
    SUBI        r11, r11, 18
    AND         r16, r11, r15                   ; check for underflow
    BRNZ        eddsa_nonce_finish_last_block

    MOVI        r12, 18
eddsa_nonce_finish_loop_l2:
    CALL        eddsa_nonce_shift

    SUBI        r12, r12, 1
    BRNZ        eddsa_nonce_finish_loop_l2

    TMAC_UP     r1

    JMP         eddsa_nonce_finish_loop_l1

eddsa_nonce_finish_last_block:

    ADDI        r11, r11, 18                    ; r11 = byte size of the last block
    BRZ         eddsa_nonce_finish_exact

    MOVI        r12, 18
    SUB         r12, r12, r11                   ; r12 = size of padding

eddsa_nonce_finish_last_loop:
    CALL        eddsa_nonce_shift

    SUBI        r11, r11, 1
    BRNZ        eddsa_nonce_finish_last_loop

    CMPI        r12, 1
    BRZ         eddsa_nonce_finish_padding_1

    MOVI        r2,  0x04
    ROR8        r2,  r2
eddsa_nonce_finish_padding_loop:
    ROLIN       r1,  r1,  r2
    ROL8        r2,  r2

    SUBI        r12, r12, 1
    BRNZ        eddsa_nonce_finish_padding_loop

    ORI         r1,  r1, 0x80
    JMP         eddsa_nonce_finish_last_update

eddsa_nonce_finish_exact:                       ; message was exactly multiple of 18 bytes
    MOVI        r1,  0
    MOVI        r3,  138
    SBIT        r1,  r1,  r3
    ORI         r1,  r1,  0x80

    JMP         eddsa_nonce_finish_last_update

eddsa_nonce_finish_padding_1:
    MOVI        r2,  0x84
    ROR8        r2,  r2
    ROLIN       r1,  r1,  r2

    JMP         eddsa_nonce_finish_last_update

eddsa_nonce_finish_last_update:
    TMAC_UP     r1

    TMAC_RD     r27

    ; Get r2 from r1
    ; Update the mask using the 256 LSBs of the previous
    CALL        extend_tmac_mask
    TMAC_IT     r7
    TMAC_IS     r27, tmac_dst_eddsa_sign

    MOVI        r1,  0x04
    MOVI        r30, 17
eddsa_nonce_finish_tmac_padding_loop_k2:
    ROL8        r1,  r1
    SUBI        r30, r30, 1
    BRNZ        eddsa_nonce_finish_tmac_padding_loop_k2
    ORI         r1, r1, 0x80

    TMAC_UP     r1
    TMAC_RD     r28
    TMAC_IT     r7      ; Destroy the TMAC state

    LD          r31, ca_q25519
    REDP        r27, r28, r27

    MOVI        r0,  ret_op_success
    MOVI        r1,  0
    JMP         set_res_word
