.include mem_leyouts/mem_leyouts_includes.s
.include spect_ops_status.s

; eddsa_verify
eddsa_verify_id .eq 0x4B
eddsa_verify_input_R .eq 0x20
eddsa_verify_input_S .eq 0x40
eddsa_verify_input_pubkey .eq 0x60
eddsa_verify_input_message0 .eq 0x80
eddsa_verify_input_message1 .eq 0xA0
eddsa_verify_output_result .eq 0x1000

_start:
    JMP eddsa_verify