_start .eq 0x8000     ; Label
ca_addr_base .eq 0x100     ; Constant
ca_ecdsa_sign_internal_Ax .eq 0x160     ; Constant
ca_ecdsa_sign_internal_Ay .eq 0x180     ; Constant
ca_ecdsa_sign_internal_s .eq 0x140     ; Constant
ca_ecdsa_sign_internal_z .eq 0x120     ; Constant
ca_ed25519_d .eq 0x240     ; Constant
ca_ed25519_key_setup_internal_prefix .eq 0x140     ; Constant
ca_ed25519_key_setup_internal_s .eq 0x120     ; Constant
ca_ed25519_smp_P2t .eq 0x260     ; Constant
ca_ed25519_smp_P2x .eq 0x200     ; Constant
ca_ed25519_smp_P2y .eq 0x220     ; Constant
ca_ed25519_smp_P2z .eq 0x240     ; Constant
ca_ed25519_xG .eq 0x260     ; Constant
ca_ed25519_yG .eq 0x280     ; Constant
ca_eddsa_sign_internal_A .eq 0x300     ; Constant
ca_eddsa_sign_internal_EAt .eq 0x3c0     ; Constant
ca_eddsa_sign_internal_EAx .eq 0x360     ; Constant
ca_eddsa_sign_internal_EAy .eq 0x380     ; Constant
ca_eddsa_sign_internal_EAz .eq 0x3a0     ; Constant
ca_eddsa_sign_internal_R .eq 0x320     ; Constant
ca_eddsa_sign_internal_S .eq 0x340     ; Constant
ca_eddsa_sign_internal_smodq .eq 0x3e0     ; Constant
ca_eddsa_verify_internal_SBt .eq 0x180     ; Constant
ca_eddsa_verify_internal_SBx .eq 0x120     ; Constant
ca_eddsa_verify_internal_SBy .eq 0x140     ; Constant
ca_eddsa_verify_internal_SBz .eq 0x160     ; Constant
ca_ffff .eq 0x2c0     ; Constant
ca_p25519 .eq 0x200     ; Constant
ca_p25519_c3 .eq 0x2a0     ; Constant
ca_p256_key_setup_internal_d .eq 0x120     ; Constant
ca_p256_key_setup_internal_w .eq 0x140     ; Constant
ca_q25519 .eq 0x220     ; Constant
ca_spect_cfg_word .eq 0x100     ; Constant
ca_spect_res_word .eq 0x1100     ; Constant
clear_id .eq 0x0     ; Constant
ecc_kbus_erase .eq 0x403     ; Constant
ecc_kbus_flush .eq 0x405     ; Constant
ecc_kbus_program .eq 0x402     ; Constant
ecc_kbus_verify_erase .eq 0x404     ; Constant
ecc_key_erase_id .eq 0x63     ; Constant
ecc_key_gen_id .eq 0x60     ; Constant
ecc_key_id .eq 0x60     ; Constant
ecc_key_input_cmd_in .eq 0x0     ; Constant
ecc_key_metadata .eq 0x400     ; Constant
ecc_key_output_result .eq 0x0     ; Constant
ecc_key_read_id .eq 0x62     ; Constant
ecc_key_read_output_pub_key .eq 0x10     ; Constant
ecc_key_store_id .eq 0x61     ; Constant
ecc_key_store_input_k .eq 0x10     ; Constant
ecc_priv_key_1 .eq 0x400     ; Constant
ecc_priv_key_2 .eq 0x401     ; Constant
ecc_priv_key_3 .eq 0x402     ; Constant
ecc_pub_key_Ax .eq 0x401     ; Constant
ecc_pub_key_Ay .eq 0x402     ; Constant
ecc_type_ed25519 .eq 0x2     ; Constant
ecc_type_p256 .eq 0x1     ; Constant
ecdsa_id .eq 0x70     ; Constant
ecdsa_input_cmd_in .eq 0x0     ; Constant
ecdsa_input_message .eq 0x10     ; Constant
ecdsa_output_result .eq 0x0     ; Constant
ecdsa_sign_dbg_id .eq 0xaf     ; Constant
ecdsa_sign_dbg_input_d .eq 0x40     ; Constant
ecdsa_sign_dbg_input_w .eq 0x60     ; Constant
ecdsa_sign_dbg_input_z .eq 0x10     ; Constant
ecdsa_sign_dbg_output_r .eq 0x1010     ; Constant
ecdsa_sign_dbg_output_s .eq 0x1030     ; Constant
ecdsa_sign_id .eq 0x70     ; Constant
ecdsa_sign_input_sch .eq 0xa0     ; Constant
ecdsa_sign_input_scn .eq 0xc0     ; Constant
ecdsa_sign_output_signature .eq 0x10     ; Constant
eddsa_R_part_id .eq 0x45     ; Constant
eddsa_e_at_once_id .eq 0x46     ; Constant
eddsa_e_finish_id .eq 0x49     ; Constant
eddsa_e_prep_id .eq 0x47     ; Constant
eddsa_e_update_id .eq 0x48     ; Constant
eddsa_finish_id .eq 0x4a     ; Constant
eddsa_finish_output_signature .eq 0x10     ; Constant
eddsa_id .eq 0x40     ; Constant
eddsa_input_message .eq 0x0     ; Constant
eddsa_nonce_finish_id .eq 0x44     ; Constant
eddsa_nonce_init_id .eq 0x42     ; Constant
eddsa_nonce_update_id .eq 0x43     ; Constant
eddsa_output_result .eq 0x0     ; Constant
eddsa_set_context_dbg_id .eq 0xbf     ; Constant
eddsa_set_context_dbg_input_prefix .eq 0x60     ; Constant
eddsa_set_context_dbg_input_s .eq 0x40     ; Constant
eddsa_set_context_id .eq 0x41     ; Constant
eddsa_set_context_input_sch .eq 0xa0     ; Constant
eddsa_set_context_input_scn .eq 0xc0     ; Constant
eddsa_set_context_input_slot .eq 0x0     ; Constant
eddsa_verify .eq 0x80d8     ; Label
eddsa_verify_fail .eq 0x81c0     ; Label
eddsa_verify_id .eq 0x4b     ; Constant
eddsa_verify_input_R .eq 0x20     ; Constant
eddsa_verify_input_S .eq 0x40     ; Constant
eddsa_verify_input_message0 .eq 0x80     ; Constant
eddsa_verify_input_message1 .eq 0xa0     ; Constant
eddsa_verify_input_pubkey .eq 0x60     ; Constant
eddsa_verify_output_result .eq 0x1000     ; Constant
eddsa_verify_success .eq 0x81cc     ; Label
inv_p25519 .eq 0x84b4     ; Label
inv_p25519_250 .eq 0x83ec     ; Label
inv_p25519_loop_100 .eq 0x8488     ; Label
inv_p25519_loop_16_1 .eq 0x8434     ; Label
inv_p25519_loop_16_2 .eq 0x844c     ; Label
inv_p25519_loop_50_1 .eq 0x8470     ; Label
inv_p25519_loop_50_2 .eq 0x84a0     ; Label
inv_p25519_loop_8 .eq 0x841c     ; Label
op_eddsa_verify .eq 0x8048     ; Label
op_sha512_final .eq 0x80a0     ; Label
op_sha512_init .eq 0x8068     ; Label
op_sha512_update .eq 0x807c     ; Label
point_add_ed25519 .eq 0x8224     ; Label
point_compress_ed25519 .eq 0x82b0     ; Label
point_dbl_ed25519 .eq 0x8274     ; Label
point_decompress_ed25519 .eq 0x82dc     ; Label
point_decompress_ed25519_add_parity .eq 0x83b4     ; Label
point_decompress_ed25519_check_X0_is_1 .eq 0x83a0     ; Label
point_decompress_ed25519_check_x_is_0 .eq 0x8394     ; Label
point_decompress_ed25519_check_x_is_0_and_X0_is_1 .eq 0x83ac     ; Label
point_decompress_ed25519_fail .eq 0x83e4     ; Label
point_decompress_ed25519_sqr .eq 0x82f8     ; Label
point_decompress_ed25519_success .eq 0x83dc     ; Label
point_decompress_ed25519_vx2_check1 .eq 0x8360     ; Label
point_decompress_ed25519_vx2_check2 .eq 0x8374     ; Label
point_decompress_ed25519_vx2_check_flag .eq 0x8388     ; Label
point_decompress_ed25519_x0_0 .eq 0x82e8     ; Label
point_decompress_ed25519_x0_1 .eq 0x82f0     ; Label
point_decompress_ed25519_x_is_p_minus_x .eq 0x83d4     ; Label
ret_ctx_err .eq 0xf1     ; Constant
ret_curve_type_err .eq 0xf4     ; Constant
ret_ecdsa_err_final_verify .eq 0x24     ; Constant
ret_ecdsa_err_inv_nonce .eq 0x21     ; Constant
ret_ecdsa_err_inv_r .eq 0x22     ; Constant
ret_ecdsa_err_inv_s .eq 0x23     ; Constant
ret_eddsa_err_final_verify .eq 0x36     ; Constant
ret_eddsa_err_inv_priv_key .eq 0x34     ; Constant
ret_eddsa_err_inv_pub_key .eq 0x35     ; Constant
ret_grv_err .eq 0xf5     ; Constant
ret_key_err .eq 0xf2     ; Constant
ret_op_id_err .eq 0xf3     ; Constant
ret_op_success .eq 0x0     ; Constant
ret_point_integrity_err .eq 0x41     ; Constant
ret_x25519_err_inv_priv_key .eq 0x11     ; Constant
ret_x25519_err_inv_pub_key .eq 0x12     ; Constant
set_res_word .eq 0x8034     ; Label
sha512_final_id .eq 0x53     ; Constant
sha512_final_output_digest0 .eq 0x1010     ; Constant
sha512_final_output_digest1 .eq 0x1030     ; Constant
sha512_id .eq 0x50     ; Constant
sha512_init_id .eq 0x51     ; Constant
sha512_input_data0 .eq 0x10     ; Constant
sha512_input_data1 .eq 0x30     ; Constant
sha512_input_data2 .eq 0x50     ; Constant
sha512_input_data3 .eq 0x70     ; Constant
sha512_one_block .eq 0x8050     ; Label
sha512_update_id .eq 0x52     ; Constant
spm_ed25519_short .eq 0x81d8     ; Label
spm_ed25519_short_loop .eq 0x81ec     ; Label
tmac_dst_ecdsa_key_setup .eq 0xa     ; Constant
tmac_dst_ecdsa_sign .eq 0xb     ; Constant
tmac_dst_eddsa_sign .eq 0xc     ; Constant
x25519_context_ehpub .eq 0x60     ; Constant
x25519_context_etpriv .eq 0x40     ; Constant
x25519_dbg_id .eq 0x9f     ; Constant
x25519_dbg_input_priv .eq 0x20     ; Constant
x25519_dbg_input_pub .eq 0x40     ; Constant
x25519_dbg_output_r .eq 0x1020     ; Constant
x25519_id .eq 0x10     ; Constant
x25519_kpair_gen_id .eq 0x11     ; Constant
x25519_kpair_gen_output_etpub .eq 0x1020     ; Constant
x25519_sc_et_eh_id .eq 0x12     ; Constant
x25519_sc_et_eh_input_ehpub .eq 0x20     ; Constant
x25519_sc_et_eh_output_r1 .eq 0x1020     ; Constant
x25519_sc_et_sh_id .eq 0x13     ; Constant
x25519_sc_et_sh_input_slot .eq 0x20     ; Constant
x25519_sc_et_sh_output_r2 .eq 0x1020     ; Constant
x25519_sc_st_eh_id .eq 0x14     ; Constant
x25519_sc_st_eh_output_r3 .eq 0x1020     ; Constant
