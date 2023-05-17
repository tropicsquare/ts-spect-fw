.include    constants_includes.s

_start:
    LD r0, ca_command

    CMPI r0, c_spect_op_sha512_init
    BRNZ next_cmd_1
    JMP sha512_init
next_cmd_1:
    CMPI r0, c_spect_op_sha512_update
    BRNZ next_cmd_2
    JMP sha512_update
next_cmd_2:
    CMPI r0, c_spect_op_sha512_final
    BRNZ next_cmd_3
    JMP sha512_final

next_cmd_3:
    CMPI r0, c_spect_op_eddsa_verify
    BRNZ next_cmd_4
    JMP eddsa_verify

next_cmd_4:
    END

.include    routines_includes.s