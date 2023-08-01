; clear
clear_id .eq 0x00
; ecc_key
ecc_key_id .eq 0x60
ecc_key_input_cmd_in .eq 0x0
ecc_key_output_result .eq 0x0
; ecc_key_gen
ecc_key_gen_id .eq 0x60
; ecc_key_store
ecc_key_store_id .eq 0x61
ecc_key_store_input_k .eq 0x10
; ecc_key_read
ecc_key_read_id .eq 0x62
ecc_key_read_output_pub_key .eq 0x10
; ecc_key_erase
ecc_key_erase_id .eq 0x63
; x25519
x25519_id .eq 0x10
x25519_context_etpriv .eq 0x40
x25519_context_ehpub .eq 0x60
; x25519_kpair_gen
x25519_kpair_gen_id .eq 0x11
x25519_kpair_gen_output_etpub .eq 0x1020
; x25519_sc_et_eh
x25519_sc_et_eh_id .eq 0x12
x25519_sc_et_eh_input_ehpub .eq 0x20
x25519_sc_et_eh_output_x1 .eq 0x1020
; x25519_sc_et_sh
x25519_sc_et_sh_id .eq 0x13
x25519_sc_et_sh_input_slot .eq 0x20
x25519_sc_et_sh_output_r2 .eq 0x1020
; x25519_sc_st_eh
x25519_sc_st_eh_id .eq 0x14
x25519_sc_st_eh_output_r3 .eq 0x1020
; eddsa
eddsa_id .eq 0x40
eddsa_input_message .eq 0x0
eddsa_output_result .eq 0x0
; eddsa_set_context
eddsa_set_context_id .eq 0x41
eddsa_set_context_input_sch .eq 0xA0
eddsa_set_context_input_scn .eq 0xC0
; eddsa_nonce_init
eddsa_nonce_init_id .eq 0x42
; eddsa_nonce_update
eddsa_nonce_update_id .eq 0x43
; eddsa_nonce_finish
eddsa_nonce_finish_id .eq 0x44
; eddsa_R_part
eddsa_R_part_id .eq 0x45
; eddsa_e_at_once
eddsa_e_at_once_id .eq 0x46
; eddsa_e_prep
eddsa_e_prep_id .eq 0x47
; eddsa_e_update
eddsa_e_update_id .eq 0x48
; eddsa_e_finish
eddsa_e_finish_id .eq 0x49
; eddsa_finish
eddsa_finish_id .eq 0x4A
eddsa_finish_output_R .eq 0x10
eddsa_finish_output_S .eq 0x30
; eddsa_verify
eddsa_verify_id .eq 0x4B
eddsa_verify_input_R .eq 0x20
eddsa_verify_input_S .eq 0x40
eddsa_verify_input_pubkey .eq 0x60
eddsa_verify_input_message0 .eq 0x80
eddsa_verify_input_message1 .eq 0xA0
eddsa_verify_output_result .eq 0x1000
; ecdsa
ecdsa_id .eq 0x70
ecdsa_input_cmd_in .eq 0x0
ecdsa_input_message .eq 0x10
ecdsa_output_result .eq 0x0
; ecdsa_sign
ecdsa_sign_id .eq 0x70
ecdsa_sign_input_sch .eq 0xA0
ecdsa_sign_input_scn .eq 0xC0
ecdsa_sign_output_R .eq 0x10
ecdsa_sign_output_S .eq 0x30
; sha512
sha512_id .eq 0x50
sha512_input_data0 .eq 0x10
sha512_input_data1 .eq 0x30
sha512_input_data2 .eq 0x50
sha512_input_data3 .eq 0x70
; sha512_init
sha512_init_id .eq 0x51
; sha512_update
sha512_update_id .eq 0x52
; sha512_final
sha512_final_id .eq 0x53
sha512_final_output_digest0 .eq 0x1010
sha512_final_output_digest1 .eq 0x1030
; x25519_dbg
x25519_dbg_id .eq 0x9F
x25519_dbg_input_priv .eq 0x20
x25519_dbg_input_pub .eq 0x40
x25519_dbg_output_r .eq 0x1020
; curve25519_rpg
curve25519_rpg_id .eq 0xD0
; ed25519_rpg
ed25519_rpg_id .eq 0xD1
; p256_spm
p256_spm_id .eq 0xD3
p256_spm_input_gx .eq 0x0
p256_spm_input_gy .eq 0x20
p256_spm_input_gk .eq 0x40
p256_spm_output_qx .eq 0x1000
p256_spm_output_qy .eq 0x1020
