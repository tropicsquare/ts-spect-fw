; ==============================================================================
;  file    
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
;   Descriptor constants
;   - config and result word address
;   - ECC type values
;   - KBUS immediates
;
; ==============================================================================

ca_spect_cfg_word .eq 0x0100
ca_spect_res_word .eq 0x1100
ecc_type_ed25519 .eq 0x02
ecc_type_p256 .eq 0x01
ecc_priv_key_1 .eq 0x400
ecc_priv_key_2 .eq 0x401
ecc_priv_key_3 .eq 0x402
ecc_key_metadata .eq 0x400
ecc_pub_key_Ax .eq 0x401
ecc_pub_key_Ay .eq 0x402
ecc_kbus_program .eq 0x402
ecc_kbus_flush .eq 0x405
