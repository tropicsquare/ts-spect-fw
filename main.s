.include constants_includes.s

_start:
    LD r0, ca_command

    CMPI r0, sha512_init_id
    BRNZ next_cmd_1
    JMP sha512_init
next_cmd_1:
    CMPI r0, sha512_update_id
    BRNZ next_cmd_2
    JMP sha512_update
next_cmd_2:
    CMPI r0, sha512_final_id
    BRNZ next_cmd_3
    JMP sha512_final

next_cmd_3:
    CMPI r0, eddsa_verify_id
    BRNZ next_cmd_4
    JMP eddsa_verify

next_cmd_4:
    END

.include routines_includes.s