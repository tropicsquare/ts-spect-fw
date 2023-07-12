; clear
clear_id .eq 0x00
; sha512
sha512_id .eq 0x50
; sha512_init
sha512_init_id .eq 0x51
; sha512_update
sha512_update_id .eq 0x52
sha512_update_input_data0 .eq 0x0020
sha512_update_input_data1 .eq 0x0040
sha512_update_input_data2 .eq 0x0060
sha512_update_input_data3 .eq 0x0080
; sha512_final
sha512_final_id .eq 0x53
sha512_final_input_data0 .eq 0x0020
sha512_final_input_data1 .eq 0x0040
sha512_final_input_data2 .eq 0x0060
sha512_final_input_data3 .eq 0x0080
sha512_final_output_digest0 .eq 0x1020
sha512_final_output_digest1 .eq 0x1040
; ecc_key
ecc_key_id .eq 0x20
ecc_key_output_result .eq 0x0000
; ecc_key_gen
ecc_key_gen_id .eq 0x21
; ecc_key_store
ecc_key_store_id .eq 0x22
ecc_key_store_input_k .eq 0x0010
; ecc_key_read
ecc_key_read_id .eq 0x23
ecc_key_read_output_pub_key .eq 0x0010
; ecc_key_erase
ecc_key_erase_id .eq 0x24
; x25519
x25519_id .eq 0x10
; x25519_kpair_gen
x25519_kpair_gen_id .eq 0x11
x25519_kpair_gen_output_etpub .eq 0x1020
; x25519_sc_et_eh
x25519_sc_et_eh_id .eq 0x12
x25519_sc_et_eh_input_ehpub .eq 0x0020
x25519_sc_et_eh_output_x1 .eq 0x1020
; x25519_sc_et_sh
x25519_sc_et_sh_id .eq 0x13
x25519_sc_et_sh_input_slot .eq 0x0020
x25519_sc_et_sh_output_r2 .eq 0x1020
; x25519_sc_st_eh
x25519_sc_st_eh_id .eq 0x14
x25519_sc_st_eh_output_r3 .eq 0x1020
; eddsa
eddsa_id .eq 0x40
; eddsa_set_context
eddsa_set_context_id .eq 0x41
eddsa_set_context_input_sch .eq 0x00A0
eddsa_set_context_input_scn .eq 0x00C0
; eddsa_nonce_init
eddsa_nonce_init_id .eq 0x42
; eddsa_nonce_update
eddsa_nonce_update_id .eq 0x43
eddsa_nonce_update_input_message .eq 0x0000
; eddsa_nonce_finish
eddsa_nonce_finish_id .eq 0x42
eddsa_nonce_finish_input_message .eq 0x0000
; eddsa_R_part
eddsa_R_part_id .eq 0x45
; eddsa_e_prep
eddsa_e_prep_id .eq 0x46
eddsa_e_prep_input_message .eq 0x0000
; eddsa_e_update
eddsa_e_update_id .eq 0x47
eddsa_e_update_input_message .eq 0x0000
; eddsa_e_finish
eddsa_e_finish_id .eq 0x48
eddsa_e_finish_input_message .eq 0x0000
; eddsa_finish
eddsa_finish_id .eq 0x49
eddsa_finish_output_r .eq 0x0010
eddsa_finish_output_s .eq 0x0010
; eddsa_verify
eddsa_verify_id .eq 0x4A
eddsa_verify_input_r .eq 0x0020
eddsa_verify_input_s .eq 0x0040
eddsa_verify_input_pubkey .eq 0x0060
eddsa_verify_input_message0 .eq 0x0080
eddsa_verify_input_message1 .eq 0x00A0
eddsa_verify_output_result .eq 0x1020
; ecdsa_sign
ecdsa_sign_id .eq 0x31
ecdsa_sign_input_message .eq 0x0010
ecdsa_sign_input_sch .eq 0x00A0
ecdsa_sign_input_scn .eq 0x00C0
ecdsa_sign_output_r .eq 0x0010
ecdsa_sign_output_s .eq 0x0010
; x25519_dbg
x25519_dbg_id .eq 0x9F
x25519_dbg_input_priv .eq 0x0020
x25519_dbg_input_pub .eq 0x0040
x25519_dbg_output_r .eq 0x1020
; curve25519_rpg
curve25519_rpg_id .eq 0xD0
; ed25519_rpg
ed25519_rpg_id .eq 0xD1
