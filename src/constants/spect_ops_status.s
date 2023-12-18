; ==============================================================================
;  file    constants/spect_op_values.s
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
;   SPECT_OP_STATUS field values 
;
; ==============================================================================

ret_op_success .eq 0x00
ret_ctx_err .eq 0xf1
ret_key_err .eq 0xf2
ret_op_id_err .eq 0xf3
ret_curve_type_err .eq 0xf4
ret_grv_err .eq 0xf5
ret_x25519_err_inv_priv_key .eq 0x11
ret_x25519_err_inv_pub_key .eq 0x12
ret_ecdsa_err_inv_nonce .eq 0x21
ret_ecdsa_err_inv_r .eq 0x22
ret_ecdsa_err_inv_s .eq 0x23
ret_ecdsa_err_final_verify .eq 0x24
ret_eddsa_err_inv_priv_key .eq 0x34
ret_eddsa_err_inv_pub_key .eq 0x35
ret_eddsa_err_final_verify .eq 0x36
ret_point_integrity_err .eq 0x41
