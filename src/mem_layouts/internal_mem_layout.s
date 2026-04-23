; ==============================================================================
;  file    mem_layouts/internal_mem_layout.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Memory constants (layout) for internal intermediate values.
;
; ==============================================================================
ca_addr_base .eq 0x0100

; ==============================================================================
;   EdDSA
; ==============================================================================
ca_eddsa_sign_internal_A .eq 0x0500
ca_eddsa_sign_internal_R .eq 0x0520
ca_eddsa_sign_internal_S .eq 0x0540
ca_eddsa_sign_internal_s1 .eq 0x0560
ca_eddsa_sign_internal_s2 .eq 0x0580

; ==============================================================================
;   Ed25519 Key Setup
; ==============================================================================
ca_ed25519_key_setup_internal_s .eq 0x0120
ca_ed25519_key_setup_internal_prefix .eq 0x0140
ca_p256_key_setup_internal_d .eq 0x0120

; ==============================================================================
;   ECDSA
; ==============================================================================
ca_p256_key_setup_internal_w .eq 0x0140
ca_ecdsa_sign_internal_z .eq 0x0120
ca_ecdsa_sign_internal_Ax .eq 0x0160
ca_ecdsa_sign_internal_Ay .eq 0x0180
ca_ecdsa_sign_internal_r .eq 0x01A0
ca_ecdsa_sign_internal_s .eq 0x01C0

; ==============================================================================
;   Scalar Point Multiplication
; ==============================================================================
ca_spm_internal_Px .eq 0x0300
ca_spm_internal_Py .eq 0x0320
ca_spm_internal_Pz .eq 0x0340
ca_spm_internal_Pt .eq 0x0380

; ==============================================================================
;   Double Scalar Point Multiplication
; ==============================================================================
;
;   Bits 9:8 of these address constants are derived from the scalars bits.
;
;           (  X        Y        Z        T )
;       O : 0x0120 - 0x0140 - 0x0160 - 0x0180
ca_dspm_point_Ox .eq 0x0120
ca_dspm_point_Oy .eq 0x0140
ca_dspm_point_Oz .eq 0x0160
ca_dspm_point_Ot .eq 0x0180

;      P1 : 0x0220 - 0x0240 - 0x0260 - 0x0280
ca_dspm_point_P1x .eq 0x0220
ca_dspm_point_P1y .eq 0x0240
ca_dspm_point_P1z .eq 0x0260
ca_dspm_point_P1t .eq 0x0280

;      P2 : 0x0320 - 0x0340 - 0x0360 - 0x0380
ca_dspm_point_P2x .eq 0x0320
ca_dspm_point_P2y .eq 0x0340
ca_dspm_point_P2z .eq 0x0360
ca_dspm_point_P2t .eq 0x0380

; P1 + P2 : 0x0420 - 0x0440 - 0x0460 - 0x0480
ca_dspm_point_P1P2x .eq 0x0420
ca_dspm_point_P1P2y .eq 0x0440
ca_dspm_point_P1P2z .eq 0x0460
ca_dspm_point_P1P2t .eq 0x0480

; ==============================================================================
;   Call Check
; ==============================================================================
ca_call_check_level_1 .eq 0x0600
ca_call_check_level_2 .eq 0x0620
ca_call_check_level_3 .eq 0x0640
ca_call_check_level_4 .eq 0x0660

; ==============================================================================
;   Others
; ==============================================================================
ca_op_link .eq 0x0700
ca_gfp_gen_dst .eq 0x0720

ca_checkpoint .eq 0x740

ca_tmac_drng_seed .eq 0x780
