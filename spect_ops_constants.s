ca_command .eq 0x0000
c_spect_op_clear .eq 0x00
; ECC Keys
c_spect_op_ecc_key_gen .eq 0x21
c_spect_op_ecc_key_store .eq 0x22
c_spect_op_ecc_key_read .eq 0x23 
c_spect_op_ecc_key_erase .eq 0x24
; Secure Channel Support
c_spect_op_x25519_kpair_gen .eq 0x11
c_spect_op_x25519_sc_et_eh .eq 0x12
c_spect_op_x25519_sc_et_sh .eq 0x13
c_spect_op_x25519_sc_st_eh .eq 0x14
; EdDSA
c_spect_op_eddsa_set_context .eq 0x41
c_spect_op_eddsa_nonce_init .eq 0x42
c_spect_op_eddsa_nonce_update .eq 0x43
c_spect_op_eddsa_nonce_finish .eq 0x44
c_spect_op_eddsa_R_part .eq 0x45
c_spect_op_eddsa_e_prep .eq 0x46
c_spect_op_eddsa_e_update .eq 0x47
c_spect_op_eddsa_e_finish .eq 0x48
c_spect_op_eddsa_finish .eq 0x49
c_spect_op_eddsa_verify .eq 0x4A
; ECDSA
c_spect_op_ecdsa_sign .eq 0x24
; SHA512
c_spect_op_sha512_init .eq 0x51
c_spect_op_sha512_update .eq 0x52
c_spect_op_sha512_final .eq 0x53