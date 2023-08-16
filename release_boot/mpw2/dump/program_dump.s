0x8000: _start:        LD        R0,256
0x8004:                MOVI      R4,255
0x8008:                AND       R0,R0,R4
0x800c:                CMPI      ,R0,82
0x8010:                BRZ       807c
0x8014:                CMPI      ,R0,81
0x8018:                BRZ       8068
0x801c:                CMPI      ,R0,83
0x8020:                BRZ       80a0
0x8024:                CMPI      ,R0,75
0x8028:                BRZ       8048
0x802c:                MOVI      R0,243
0x8030:                MOVI      R1,1
0x8034: set_res_word:  ROL8      R1,R1
0x8038:                ROL8      R1,R1
0x803c:                ADD       R0,R0,R1
0x8040:                ST        R0,4352
0x8044:                END       
0x8048: op_eddsa_verify:JMP       80d8
0x804c:                JMP       8034
0x8050: sha512_one_block:SWE       R3,R3
0x8054:                SWE       R2,R2
0x8058:                SWE       R1,R1
0x805c:                SWE       R0,R0
0x8060:                HASH      R4,R0
0x8064:                RET       
0x8068: op_sha512_init:HASH_IT   
0x806c:                MOVI      R0,0
0x8070:                MOVI      R1,0
0x8074:                MOVI      R30,81
0x8078:                JMP       8034
0x807c: op_sha512_update:LD        R3,16
0x8080:                LD        R2,48
0x8084:                LD        R1,80
0x8088:                LD        R0,112
0x808c:                CALL      8050
0x8090:                MOVI      R0,0
0x8094:                MOVI      R1,0
0x8098:                MOVI      R30,82
0x809c:                JMP       8034
0x80a0: op_sha512_final:LD        R3,16
0x80a4:                LD        R2,48
0x80a8:                LD        R1,80
0x80ac:                LD        R0,112
0x80b0:                CALL      8050
0x80b4:                SWE       R4,R4
0x80b8:                SWE       R5,R5
0x80bc:                ST        R5,4112
0x80c0:                ST        R4,4144
0x80c4:                HASH_IT   
0x80c8:                MOVI      R0,0
0x80cc:                MOVI      R1,64
0x80d0:                MOVI      R30,83
0x80d4:                JMP       8034
0x80d8: eddsa_verify:  LD        R28,64
0x80dc:                LD        R31,12608
0x80e0:                LD        R6,12704
0x80e4:                LD        R11,12736
0x80e8:                LD        R12,12768
0x80ec:                MOVI      R13,1
0x80f0:                MUL25519  R14,R11,R12
0x80f4:                CALL      81d0
0x80f8:                ST        R7,288
0x80fc:                ST        R8,320
0x8100:                ST        R9,352
0x8104:                ST        R10,384
0x8108:                LD        R24,160
0x810c:                LD        R25,128
0x8110:                LD        R26,96
0x8114:                LD        R27,32
0x8118:                SWE       R20,R24
0x811c:                SWE       R21,R25
0x8120:                SWE       R22,R26
0x8124:                SWE       R23,R27
0x8128:                HASH_IT   
0x812c:                HASH      R28,R20
0x8130:                MOVI      R3,128
0x8134:                ROR8      R3,R3
0x8138:                MOVI      R2,0
0x813c:                MOVI      R1,0
0x8140:                MOVI      R0,1024
0x8144:                HASH      R28,R0
0x8148:                SWE       R28,R28
0x814c:                SWE       R29,R29
0x8150:                LD        R31,12640
0x8154:                REDP      R28,R28,R29
0x8158:                LD        R31,12608
0x815c:                MOV       R12,R26
0x8160:                CALL      82d4
0x8164:                XORI      R1,R1,0
0x8168:                BRNZ      81b8
0x816c:                MOVI      R13,1
0x8170:                MUL25519  R14,R11,R12
0x8174:                CALL      81d0
0x8178:                MOVI      R0,0
0x817c:                SUBP      R7,R0,R7
0x8180:                SUBP      R10,R0,R10
0x8184:                LD        R11,288
0x8188:                LD        R12,320
0x818c:                LD        R13,352
0x8190:                LD        R14,384
0x8194:                CALL      821c
0x8198:                MOV       R7,R11
0x819c:                MOV       R8,R12
0x81a0:                MOV       R9,R13
0x81a4:                CALL      82a8
0x81a8:                MOVI      R0,0
0x81ac:                MOVI      R1,1
0x81b0:                XOR       R2,R23,R8
0x81b4:                BRZ       81c4
0x81b8: eddsa_verify_fail:MOVI      R2,1
0x81bc:                ST        R2,4096
0x81c0:                JMP       8034
0x81c4: eddsa_verify_success:MOVI      R2,0
0x81c8:                ST        R2,4096
0x81cc:                JMP       8034
0x81d0: spm_ed25519_short:MOVI      R7,0
0x81d4:                MOVI      R8,1
0x81d8:                MOVI      R9,1
0x81dc:                MOVI      R10,0
0x81e0:                MOVI      R30,256
0x81e4: spm_ed25519_short_loop:ROL       R28,R28
0x81e8:                CSWAP     R7,R11
0x81ec:                CSWAP     R8,R12
0x81f0:                CSWAP     R9,R13
0x81f4:                CSWAP     R10,R14
0x81f8:                CALL      821c
0x81fc:                CALL      826c
0x8200:                CSWAP     R7,R11
0x8204:                CSWAP     R8,R12
0x8208:                CSWAP     R9,R13
0x820c:                CSWAP     R10,R14
0x8210:                SUBI      R30,R30,1
0x8214:                BRNZ      81e4
0x8218:                RET       
0x821c: point_add_ed25519:SUBP      R0,R8,R7
0x8220:                SUBP      R1,R12,R11
0x8224:                MUL25519  R0,R0,R1
0x8228:                ADDP      R1,R8,R7
0x822c:                ADDP      R2,R12,R11
0x8230:                MUL25519  R1,R1,R2
0x8234:                MUL25519  R2,R10,R14
0x8238:                MUL25519  R2,R2,R6
0x823c:                ADDP      R2,R2,R2
0x8240:                MUL25519  R3,R9,R13
0x8244:                ADDP      R3,R3,R3
0x8248:                SUBP      R4,R1,R0
0x824c:                ADDP      R0,R1,R0
0x8250:                SUBP      R1,R3,R2
0x8254:                ADDP      R2,R3,R2
0x8258:                MUL25519  R11,R4,R1
0x825c:                MUL25519  R14,R4,R0
0x8260:                MUL25519  R12,R2,R0
0x8264:                MUL25519  R13,R2,R1
0x8268:                RET       
0x826c: point_dbl_ed25519:MUL25519  R0,R7,R7
0x8270:                MUL25519  R1,R8,R8
0x8274:                MUL25519  R2,R9,R9
0x8278:                ADDP      R2,R2,R2
0x827c:                ADDP      R3,R0,R1
0x8280:                ADDP      R4,R7,R8
0x8284:                MUL25519  R4,R4,R4
0x8288:                SUBP      R4,R3,R4
0x828c:                SUBP      R0,R0,R1
0x8290:                ADDP      R1,R2,R0
0x8294:                MUL25519  R7,R4,R1
0x8298:                MUL25519  R9,R0,R1
0x829c:                MUL25519  R8,R0,R3
0x82a0:                MUL25519  R10,R4,R3
0x82a4:                RET       
0x82a8: point_compress_ed25519:MOV       R1,R9
0x82ac:                CALL      84a4
0x82b0:                MUL25519  R7,R7,R1
0x82b4:                MUL25519  R8,R8,R1
0x82b8:                MOVI      R1,1
0x82bc:                AND       R7,R7,R1
0x82c0:                ROL       R8,R8
0x82c4:                OR        R8,R8,R7
0x82c8:                ROR       R8,R8
0x82cc:                SWE       R8,R8
0x82d0:                RET       
0x82d4: point_decompress_ed25519:MOV       R16,R12
0x82d8:                LSL       R16,R16
0x82dc:                BRC       82e8
0x82e0: point_decompress_ed25519_x0_0:MOVI      R22,0
0x82e4:                JMP       82f0
0x82e8: point_decompress_ed25519_x0_1:MOVI      R22,1
0x82ec:                JMP       82f0
0x82f0: point_decompress_ed25519_sqr:LSR       R16,R16
0x82f4:                MOV       R12,R16
0x82f8:                MUL25519  R16,R16,R16
0x82fc:                MOVI      R1,1
0x8300:                SUBP      R20,R16,R1
0x8304:                MUL25519  R16,R16,R6
0x8308:                ADDP      R21,R16,R1
0x830c:                MUL25519  R18,R21,R21
0x8310:                MUL25519  R18,R18,R21
0x8314:                MUL25519  R19,R18,R20
0x8318:                MUL25519  R18,R18,R18
0x831c:                MUL25519  R18,R18,R21
0x8320:                MUL25519  R1,R18,R20
0x8324:                MOV       R16,R1
0x8328:                CALL      83dc
0x832c:                MUL25519  R18,R2,R2
0x8330:                MUL25519  R18,R18,R18
0x8334:                MUL25519  R18,R18,R16
0x8338:                MUL25519  R18,R18,R19
0x833c:                MUL25519  R16,R18,R18
0x8340:                MUL25519  R16,R16,R21
0x8344:                LD        R1,12800
0x8348:                MUL25519  R17,R18,R1
0x834c:                MOVI      R1,0
0x8350:                XOR       R30,R16,R20
0x8354:                BRNZ      8360
0x8358:                MOV       R0,R18
0x835c:                MOVI      R1,1
0x8360: point_decompress_ed25519_vx2_check2:MOVI      R30,0
0x8364:                SUBP      R20,R30,R20
0x8368:                XOR       R30,R16,R20
0x836c:                BRNZ      8378
0x8370:                MOV       R0,R17
0x8374:                MOVI      R1,1
0x8378: point_decompress_ed25519_vx2_check_flag:CMPI      ,R1,0
0x837c:                BRZ       83d4
0x8380:                MOVI      R1,0
0x8384: point_decompress_ed25519_check_x_is_0:XOR       R30,R30,R0
0x8388:                BRNZ      8390
0x838c:                ORI       R1,R1,1
0x8390: point_decompress_ed25519_check_X0_is_1:CMPI      ,R22,1
0x8394:                BRNZ      839c
0x8398:                ORI       R1,R1,2
0x839c: point_decompress_ed25519_check_x_is_0_and_X0_is_1:CMPI      ,R1,3
0x83a0:                BRZ       83d4
0x83a4: point_decompress_ed25519_add_parity:MOVI      R3,0
0x83a8:                SUBP      R3,R3,R0
0x83ac:                MOVI      R30,1
0x83b0:                AND       R1,R0,R30
0x83b4:                CMP       ,R1,R22
0x83b8:                BRNZ      83c4
0x83bc:                MOV       R11,R0
0x83c0:                JMP       83cc
0x83c4: point_decompress_ed25519_x_is_p_minus_x:MOV       R11,R3
0x83c8:                JMP       83cc
0x83cc: point_decompress_ed25519_success:MOVI      R1,0
0x83d0:                RET       
0x83d4: point_decompress_ed25519_fail:MOVI      R1,1
0x83d8:                RET       
0x83dc: inv_p25519_250:MUL25519  R2,R1,R1
0x83e0:                MUL25519  R4,R2,R1
0x83e4:                MUL25519  R3,R4,R4
0x83e8:                MUL25519  R3,R3,R3
0x83ec:                MUL25519  R2,R4,R3
0x83f0:                MUL25519  R3,R2,R2
0x83f4:                MUL25519  R3,R3,R3
0x83f8:                MUL25519  R3,R3,R3
0x83fc:                MUL25519  R3,R3,R3
0x8400:                MUL25519  R2,R2,R3
0x8404:                MUL25519  R3,R2,R2
0x8408:                MOVI      R30,7
0x840c: inv_p25519_loop_8:MUL25519  R3,R3,R3
0x8410:                SUBI      R30,R30,1
0x8414:                BRNZ      840c
0x8418:                MUL25519  R5,R2,R3
0x841c:                MUL25519  R3,R5,R5
0x8420:                MOVI      R30,15
0x8424: inv_p25519_loop_16_1:MUL25519  R3,R3,R3
0x8428:                SUBI      R30,R30,1
0x842c:                BRNZ      8424
0x8430:                MUL25519  R2,R5,R3
0x8434:                MUL25519  R3,R2,R2
0x8438:                MOVI      R30,15
0x843c: inv_p25519_loop_16_2:MUL25519  R3,R3,R3
0x8440:                SUBI      R30,R30,1
0x8444:                BRNZ      843c
0x8448:                MUL25519  R2,R5,R3
0x844c:                MUL25519  R2,R2,R2
0x8450:                MUL25519  R2,R2,R2
0x8454:                MUL25519  R5,R2,R4
0x8458:                MUL25519  R3,R5,R5
0x845c:                MOVI      R30,49
0x8460: inv_p25519_loop_50_1:MUL25519  R3,R3,R3
0x8464:                SUBI      R30,R30,1
0x8468:                BRNZ      8460
0x846c:                MUL25519  R2,R5,R3
0x8470:                MUL25519  R3,R2,R2
0x8474:                MOVI      R30,99
0x8478: inv_p25519_loop_100:MUL25519  R3,R3,R3
0x847c:                SUBI      R30,R30,1
0x8480:                BRNZ      8478
0x8484:                MUL25519  R2,R2,R3
0x8488:                MUL25519  R3,R2,R2
0x848c:                MOVI      R30,49
0x8490: inv_p25519_loop_50_2:MUL25519  R3,R3,R3
0x8494:                SUBI      R30,R30,1
0x8498:                BRNZ      8490
0x849c:                MUL25519  R2,R3,R5
0x84a0:                RET       
0x84a4: inv_p25519:    CALL      83dc
0x84a8:                MUL25519  R3,R2,R2
0x84ac:                MUL25519  R3,R3,R3
0x84b0:                MUL25519  R3,R3,R1
0x84b4:                MUL25519  R3,R3,R3
0x84b8:                MUL25519  R3,R3,R3
0x84bc:                MUL25519  R3,R3,R3
0x84c0:                MUL25519  R1,R3,R4
0x84c4:                RET       