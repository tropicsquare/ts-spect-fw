; Internal Address Constants for intermediate values
ca_addr_base .eq 0x0100
ca_ed25519_smp_P2x .eq 0x0200
ca_ed25519_smp_P2y .eq 0x0220
ca_ed25519_smp_P2z .eq 0x0240
ca_ed25519_smp_P2t .eq 0x0260
; EdDSA --------------------------------------------- 
ca_eddsa_sign_internal_A .eq 0x0300
ca_eddsa_sign_internal_R .eq 0x0320
ca_eddsa_sign_internal_S .eq 0x0340
ca_eddsa_sign_internal_EAx .eq 0x0360
ca_eddsa_sign_internal_EAy .eq 0x0380
ca_eddsa_sign_internal_EAz .eq 0x03A0
ca_eddsa_sign_internal_EAt .eq 0x03C0
ca_eddsa_sign_internal_smodq .eq 0x03E0

; EdDSA Verify -------------------------------------- 
ca_eddsa_verify_internal_SBx .eq 0x0120
ca_eddsa_verify_internal_SBy .eq 0x0140
ca_eddsa_verify_internal_SBz .eq 0x0160
ca_eddsa_verify_internal_SBt .eq 0x0180

ca_ed25519_key_setup_internal_s .eq 0x0120
ca_ed25519_key_setup_internal_prefix .eq 0x0140
ca_p256_key_setup_internal_d .eq 0x0120
; ECDSA --------------------------------------------
ca_p256_key_setup_internal_w .eq 0x0140
ca_ecdsa_sign_internal_z .eq 0x0120
ca_ecdsa_sign_internal_s .eq 0x0140
ca_ecdsa_sign_internal_Ax .eq 0x0160
ca_ecdsa_sign_internal_Ay .eq 0x0180