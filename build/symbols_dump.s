_start .eq 0x8000     ; Label
bp_eddsa_verify_after_hram .eq 0x8614     ; Label
bp_eddsa_verify_deca .eq 0x8628     ; Label
bp_eddsa_verify_encq .eq 0x866c     ; Label
bp_eddsa_verify_exa .eq 0x863c     ; Label
bp_eddsa_verify_sxb .eq 0x85cc     ; Label
ca_command .eq 0x0     ; Constant
ca_curve25519_a .eq 0x31e0     ; Constant
ca_dst_template .eq 0x3220     ; Constant
ca_ecdsa_b .eq 0x3060     ; Constant
ca_ecdsa_exp_low .eq 0x3040     ; Constant
ca_ecdsa_p .eq 0x3000     ; Constant
ca_ecdsa_q .eq 0x3020     ; Constant
ca_ecdsa_xG .eq 0x3080     ; Constant
ca_ecdsa_yG .eq 0x30a0     ; Constant
ca_eddsa_8q .eq 0x3100     ; Constant
ca_eddsa_d .eq 0x3120     ; Constant
ca_eddsa_m1 .eq 0x3180     ; Constant
ca_eddsa_p .eq 0x30c0     ; Constant
ca_eddsa_q .eq 0x30e0     ; Constant
ca_eddsa_verify_internal_SBt .eq 0x160     ; Constant
ca_eddsa_verify_internal_SBx .eq 0x100     ; Constant
ca_eddsa_verify_internal_SBy .eq 0x120     ; Constant
ca_eddsa_verify_internal_SBz .eq 0x140     ; Constant
ca_eddsa_xG .eq 0x3140     ; Constant
ca_eddsa_yG .eq 0x3160     ; Constant
ca_ffff .eq 0x31c0     ; Constant
ca_op_status .eq 0x1000     ; Constant
ca_pg_curve25519_c3 .eq 0x3200     ; Constant
ca_x25519_a24 .eq 0x31a0     ; Constant
compose_exp_tag .eq 0x8710     ; Label
curve25519_point_generate .eq 0x8448     ; Label
curve25519_point_generate_xn_next .eq 0x8550     ; Label
curve25519_point_generate_xn_x1n .eq 0x8540     ; Label
curve25519_point_generate_xn_x2n .eq 0x8548     ; Label
curve25519_point_generate_y1_next .eq 0x84f0     ; Label
curve25519_point_generate_y1_y11 .eq 0x84e0     ; Label
curve25519_point_generate_y1_y12 .eq 0x84e8     ; Label
curve25519_point_generate_y2_next .eq 0x852c     ; Label
curve25519_point_generate_y2_y21 .eq 0x851c     ; Label
curve25519_point_generate_y2_y22 .eq 0x8524     ; Label
curve25519_point_generate_y_final .eq 0x8588     ; Label
curve25519_point_generate_y_minus .eq 0x8578     ; Label
curve25519_point_generate_y_next .eq 0x8564     ; Label
curve25519_point_generate_y_plus .eq 0x8580     ; Label
curve25519_point_generate_y_y1 .eq 0x8554     ; Label
curve25519_point_generate_y_y2 .eq 0x855c     ; Label
curve25519_rpg_id .eq 0xd0     ; Constant
eddsa_verify .eq 0x859c     ; Label
eddsa_verify_fail .eq 0x867c     ; Label
eddsa_verify_id .eq 0x4a     ; Constant
eddsa_verify_input_message0 .eq 0x80     ; Constant
eddsa_verify_input_message1 .eq 0xa0     ; Constant
eddsa_verify_input_pubkey .eq 0x60     ; Constant
eddsa_verify_input_r .eq 0x20     ; Constant
eddsa_verify_input_s .eq 0x40     ; Constant
eddsa_verify_output_result .eq 0x1020     ; Constant
eddsa_verify_success .eq 0x8688     ; Label
inv_p25519 .eq 0x8220     ; Label
inv_p25519_250 .eq 0x8158     ; Label
inv_p25519_loop_100 .eq 0x81f4     ; Label
inv_p25519_loop_16_1 .eq 0x81a0     ; Label
inv_p25519_loop_16_2 .eq 0x81b8     ; Label
inv_p25519_loop_50_1 .eq 0x81dc     ; Label
inv_p25519_loop_50_2 .eq 0x820c     ; Label
inv_p25519_loop_8 .eq 0x8188     ; Label
inv_q256 .eq 0x805c     ; Label
inv_q256_loop_16 .eq 0x80b0     ; Label
inv_q256_loop_32 .eq 0x80f4     ; Label
inv_q256_loop_64 .eq 0x80d0     ; Label
inv_q256_loop_8 .eq 0x8090     ; Label
inv_q256_loop_lowpart .eq 0x8114     ; Label
inv_q256_loop_lowpart_back .eq 0x8148     ; Label
inv_q256_loop_x0 .eq 0x8124     ; Label
inv_q256_loop_x01 .eq 0x812c     ; Label
inv_q256_loop_x1 .eq 0x8134     ; Label
inv_q256_loop_x10 .eq 0x813c     ; Label
inv_q256_loop_x11 .eq 0x8144     ; Label
map_to_curve_elligator2_curve25519 .eq 0x8468     ; Label
next_cmd_1 .eq 0x8010     ; Label
next_cmd_2 .eq 0x801c     ; Label
next_cmd_3 .eq 0x8028     ; Label
next_cmd_4 .eq 0x8034     ; Label
next_cmd_end .eq 0x8058     ; Label
point_add_ed25519 .eq 0x8370     ; Label
point_compress_ed25519 .eq 0x8244     ; Label
point_decompress_ed25519 .eq 0x826c     ; Label
point_decompress_ed25519_check_X0_is_1 .eq 0x8328     ; Label
point_decompress_ed25519_check_x_is_0_and_X0_is_1 .eq 0x8334     ; Label
point_decompress_ed25519_fail .eq 0x8368     ; Label
point_decompress_ed25519_sqr .eq 0x8288     ; Label
point_decompress_ed25519_success .eq 0x8360     ; Label
point_decompress_ed25519_vx2_check2 .eq 0x8300     ; Label
point_decompress_ed25519_vx2_check_flag .eq 0x8310     ; Label
point_decompress_ed25519_x0_1 .eq 0x8280     ; Label
point_decompress_ed25519_x_is_p_minus_x .eq 0x8358     ; Label
point_dub_ed25519 .eq 0x83c0     ; Label
sha512_final .eq 0x86dc     ; Label
sha512_final_id .eq 0x53     ; Constant
sha512_final_input_data0 .eq 0x20     ; Constant
sha512_final_input_data1 .eq 0x40     ; Constant
sha512_final_input_data2 .eq 0x60     ; Constant
sha512_final_input_data3 .eq 0x80     ; Constant
sha512_final_output_digest0 .eq 0x1020     ; Constant
sha512_final_output_digest1 .eq 0x1040     ; Constant
sha512_init .eq 0x86ac     ; Label
sha512_init_id .eq 0x51     ; Constant
sha512_one_block .eq 0x8694     ; Label
sha512_update .eq 0x86bc     ; Label
sha512_update_id .eq 0x52     ; Constant
sha512_update_input_data0 .eq 0x20     ; Constant
sha512_update_input_data1 .eq 0x40     ; Constant
sha512_update_input_data2 .eq 0x60     ; Constant
sha512_update_input_data3 .eq 0x80     ; Constant
spm_ed25519_short .eq 0x83fc     ; Label
spm_ed25519_short_loop .eq 0x8410     ; Label
x25519_dbg_id .eq 0x9f     ; Constant
x25519_dbg_input_priv .eq 0x20     ; Constant
x25519_dbg_input_pub .eq 0x40     ; Constant
x25519_dbg_output_r .eq 0x1020     ; Constant
