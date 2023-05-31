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
; eddsa_verify
eddsa_verify_id .eq 0x4A
eddsa_verify_input_r .eq 0x0020
eddsa_verify_input_s .eq 0x0040
eddsa_verify_input_pubkey .eq 0x0060
eddsa_verify_input_message0 .eq 0x0080
eddsa_verify_input_message1 .eq 0x00A0
eddsa_verify_output_result .eq 0x1020
