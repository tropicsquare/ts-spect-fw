0x8000: _start:        LD        R0,0
0x8004:                CMPI      ,R0,81
0x8008:                BRNZ      8010
0x800c:                JMP       86ac
0x8010: next_cmd_1:    CMPI      ,R0,82
0x8014:                BRNZ      801c
0x8018:                JMP       86bc
0x801c: next_cmd_2:    CMPI      ,R0,83
0x8020:                BRNZ      8028
0x8024:                JMP       86dc
0x8028: next_cmd_3:    CMPI      ,R0,74
0x802c:                BRNZ      8034
0x8030:                JMP       859c
0x8034: next_cmd_4:    CMPI      ,R0,208
0x8038:                BRNZ      8058
0x803c:                LD        R1,12832
0x8040:                ORI       R1,R1,216
0x8044:                ROL8      R1,R1
0x8048:                CALL      8448
0x804c:                ST        R10,4096
0x8050:                ST        R11,4128
0x8054:                END       
0x8058: next_cmd_end:  END       
0x805c: inv_q256:      MULP      R2,R26,R26
0x8060:                MULP      R3,R2,R26
0x8064:                MULP      R4,R3,R3
0x8068:                MULP      R4,R4,R4
0x806c:                MULP      R5,R4,R3
0x8070:                MULP      R4,R5,R5
0x8074:                MULP      R4,R4,R4
0x8078:                MULP      R4,R4,R4
0x807c:                MULP      R4,R4,R4
0x8080:                MULP      R5,R4,R5
0x8084:                MULP      R4,R5,R5
0x8088:                MULP      R4,R4,R4
0x808c:                MOVI      R30,6
0x8090: inv_q256_loop_8:MULP      R4,R4,R4
0x8094:                MULP      R4,R4,R4
0x8098:                MULP      R4,R4,R4
0x809c:                SUBI      R30,R30,3
0x80a0:                BRNZ      8090
0x80a4:                MULP      R5,R4,R5
0x80a8:                MULP      R4,R5,R5
0x80ac:                MOVI      R30,15
0x80b0: inv_q256_loop_16:MULP      R4,R4,R4
0x80b4:                MULP      R4,R4,R4
0x80b8:                MULP      R4,R4,R4
0x80bc:                SUBI      R30,R30,3
0x80c0:                BRNZ      80b0
0x80c4:                MULP      R6,R4,R5
0x80c8:                MULP      R4,R6,R6
0x80cc:                MOVI      R30,63
0x80d0: inv_q256_loop_64:MULP      R4,R4,R4
0x80d4:                MULP      R4,R4,R4
0x80d8:                MULP      R4,R4,R4
0x80dc:                SUBI      R30,R30,3
0x80e0:                BRNZ      80d0
0x80e4:                MULP      R5,R4,R6
0x80e8:                MULP      R4,R5,R5
0x80ec:                MULP      R4,R4,R4
0x80f0:                MOVI      R30,30
0x80f4: inv_q256_loop_32:MULP      R4,R4,R4
0x80f8:                MULP      R4,R4,R4
0x80fc:                MULP      R4,R4,R4
0x8100:                SUBI      R30,R30,3
0x8104:                BRNZ      80f4
0x8108:                MULP      R4,R4,R6
0x810c:                LD        R5,12352
0x8110:                MOVI      R30,128
0x8114: inv_q256_loop_lowpart:MULP      R4,R4,R4
0x8118:                MULP      R4,R4,R4
0x811c:                LSL       R5,R5
0x8120:                BRC       8134
0x8124: inv_q256_loop_x0:LSL       R5,R5
0x8128:                BRNC      8148
0x812c: inv_q256_loop_x01:MULP      R4,R4,R26
0x8130:                JMP       8148
0x8134: inv_q256_loop_x1:LSL       R5,R5
0x8138:                BRC       8144
0x813c: inv_q256_loop_x10:MULP      R4,R4,R2
0x8140:                JMP       8148
0x8144: inv_q256_loop_x11:MULP      R4,R4,R3
0x8148: inv_q256_loop_lowpart_back:SUBI      R30,R30,2
0x814c:                BRNZ      8114
0x8150:                MOV       R26,R4
0x8154:                RET       
0x8158: inv_p25519_250:MUL25519  R2,R1,R1
0x815c:                MUL25519  R4,R2,R1
0x8160:                MUL25519  R3,R4,R4
0x8164:                MUL25519  R3,R3,R3
0x8168:                MUL25519  R2,R4,R3
0x816c:                MUL25519  R3,R2,R2
0x8170:                MUL25519  R3,R3,R3
0x8174:                MUL25519  R3,R3,R3
0x8178:                MUL25519  R3,R3,R3
0x817c:                MUL25519  R2,R2,R3
0x8180:                MUL25519  R3,R2,R2
0x8184:                MOVI      R30,7
0x8188: inv_p25519_loop_8:MUL25519  R3,R3,R3
0x818c:                SUBI      R30,R30,1
0x8190:                BRNZ      8188
0x8194:                MUL25519  R5,R2,R3
0x8198:                MUL25519  R3,R5,R5
0x819c:                MOVI      R30,15
0x81a0: inv_p25519_loop_16_1:MUL25519  R3,R3,R3
0x81a4:                SUBI      R30,R30,1
0x81a8:                BRNZ      81a0
0x81ac:                MUL25519  R2,R5,R3
0x81b0:                MUL25519  R3,R2,R2
0x81b4:                MOVI      R30,15
0x81b8: inv_p25519_loop_16_2:MUL25519  R3,R3,R3
0x81bc:                SUBI      R30,R30,1
0x81c0:                BRNZ      81b8
0x81c4:                MUL25519  R2,R5,R3
0x81c8:                MUL25519  R2,R2,R2
0x81cc:                MUL25519  R2,R2,R2
0x81d0:                MUL25519  R5,R2,R4
0x81d4:                MUL25519  R3,R5,R5
0x81d8:                MOVI      R30,49
0x81dc: inv_p25519_loop_50_1:MUL25519  R3,R3,R3
0x81e0:                SUBI      R30,R30,1
0x81e4:                BRNZ      81dc
0x81e8:                MUL25519  R2,R5,R3
0x81ec:                MUL25519  R3,R2,R2
0x81f0:                MOVI      R30,99
0x81f4: inv_p25519_loop_100:MUL25519  R3,R3,R3
0x81f8:                SUBI      R30,R30,1
0x81fc:                BRNZ      81f4
0x8200:                MUL25519  R2,R2,R3
0x8204:                MUL25519  R3,R2,R2
0x8208:                MOVI      R30,49
0x820c: inv_p25519_loop_50_2:MUL25519  R3,R3,R3
0x8210:                SUBI      R30,R30,1
0x8214:                BRNZ      820c
0x8218:                MUL25519  R2,R3,R5
0x821c:                RET       
0x8220: inv_p25519:    CALL      8158
0x8224:                MUL25519  R3,R2,R2
0x8228:                MUL25519  R3,R3,R3
0x822c:                MUL25519  R3,R3,R1
0x8230:                MUL25519  R3,R3,R3
0x8234:                MUL25519  R3,R3,R3
0x8238:                MUL25519  R3,R3,R3
0x823c:                MUL25519  R1,R3,R4
0x8240:                RET       
0x8244: point_compress_ed25519:MOV       R1,R9
0x8248:                CALL      8220
0x824c:                MUL25519  R7,R7,R1
0x8250:                MUL25519  R8,R8,R1
0x8254:                MOVI      R1,1
0x8258:                AND       R7,R7,R1
0x825c:                ROL       R8,R8
0x8260:                OR        R8,R8,R7
0x8264:                ROR       R8,R8
0x8268:                RET       
0x826c: point_decompress_ed25519:MOV       R16,R12
0x8270:                LSL       R16,R16
0x8274:                BRC       8280
0x8278:                MOVI      R22,0
0x827c:                JMP       8288
0x8280: point_decompress_ed25519_x0_1:MOVI      R22,1
0x8284:                JMP       8288
0x8288: point_decompress_ed25519_sqr:LSR       R16,R16
0x828c:                MOV       R12,R16
0x8290:                MUL25519  R16,R16,R16
0x8294:                MOVI      R1,1
0x8298:                SUBP      R20,R16,R1
0x829c:                MUL25519  R16,R16,R6
0x82a0:                ADDP      R21,R16,R1
0x82a4:                MUL25519  R18,R21,R21
0x82a8:                MUL25519  R18,R18,R21
0x82ac:                MUL25519  R19,R18,R20
0x82b0:                MUL25519  R18,R18,R18
0x82b4:                MUL25519  R18,R18,R21
0x82b8:                MUL25519  R1,R18,R20
0x82bc:                MOV       R16,R1
0x82c0:                CALL      8158
0x82c4:                MUL25519  R18,R2,R2
0x82c8:                MUL25519  R18,R18,R18
0x82cc:                MUL25519  R18,R18,R16
0x82d0:                MUL25519  R18,R18,R19
0x82d4:                MUL25519  R16,R18,R18
0x82d8:                MUL25519  R16,R16,R21
0x82dc:                LD        R1,12672
0x82e0:                MUL25519  R17,R18,R1
0x82e4:                SUBP      R19,R16,R20
0x82e8:                ADDP      R20,R16,R20
0x82ec:                MOVI      R1,0
0x82f0:                CMPA      ,R19,0
0x82f4:                BRNZ      8300
0x82f8:                MOV       R0,R18
0x82fc:                MOVI      R1,1
0x8300: point_decompress_ed25519_vx2_check2:CMPA      ,R20,0
0x8304:                BRNZ      8310
0x8308:                MOV       R0,R17
0x830c:                MOVI      R1,1
0x8310: point_decompress_ed25519_vx2_check_flag:CMPI      ,R1,0
0x8314:                BRZ       8368
0x8318:                MOVI      R1,0
0x831c:                CMPA      ,R0,0
0x8320:                BRNZ      8328
0x8324:                ORI       R1,R1,1
0x8328: point_decompress_ed25519_check_X0_is_1:CMPI      ,R22,1
0x832c:                BRNZ      8334
0x8330:                ORI       R1,R1,2
0x8334: point_decompress_ed25519_check_x_is_0_and_X0_is_1:CMPI      ,R1,3
0x8338:                BRZ       8368
0x833c:                MOVI      R3,0
0x8340:                SUBP      R3,R3,R0
0x8344:                ANDI      R1,R0,1
0x8348:                CMP       ,R1,R22
0x834c:                BRZ       8358
0x8350:                MOV       R11,R0
0x8354:                JMP       8360
0x8358: point_decompress_ed25519_x_is_p_minus_x:MOV       R11,R3
0x835c:                JMP       8360
0x8360: point_decompress_ed25519_success:MOVI      R1,0
0x8364:                RET       
0x8368: point_decompress_ed25519_fail:MOVI      R1,1
0x836c:                RET       
0x8370: point_add_ed25519:SUBP      R0,R8,R7
0x8374:                SUBP      R1,R12,R11
0x8378:                MUL25519  R0,R0,R1
0x837c:                ADDP      R1,R8,R7
0x8380:                ADDP      R2,R12,R11
0x8384:                MUL25519  R1,R1,R2
0x8388:                MUL25519  R2,R10,R14
0x838c:                MUL25519  R2,R2,R6
0x8390:                ADDP      R2,R2,R2
0x8394:                MUL25519  R3,R9,R13
0x8398:                ADDP      R3,R3,R3
0x839c:                SUBP      R4,R1,R0
0x83a0:                ADDP      R0,R1,R0
0x83a4:                SUBP      R1,R3,R2
0x83a8:                ADDP      R2,R3,R2
0x83ac:                MUL25519  R11,R4,R1
0x83b0:                MUL25519  R14,R4,R0
0x83b4:                MUL25519  R12,R2,R0
0x83b8:                MUL25519  R13,R2,R1
0x83bc:                RET       
0x83c0: point_dub_ed25519:MUL25519  R0,R7,R7
0x83c4:                MUL25519  R1,R8,R8
0x83c8:                MUL25519  R2,R9,R9
0x83cc:                ADDP      R2,R2,R2
0x83d0:                ADDP      R3,R0,R1
0x83d4:                ADDP      R4,R7,R8
0x83d8:                MUL25519  R4,R4,R4
0x83dc:                SUBP      R4,R3,R4
0x83e0:                SUBP      R0,R0,R1
0x83e4:                ADDP      R1,R2,R0
0x83e8:                MUL25519  R7,R4,R1
0x83ec:                MUL25519  R9,R0,R1
0x83f0:                MUL25519  R8,R0,R3
0x83f4:                MUL25519  R10,R4,R3
0x83f8:                RET       
0x83fc: spm_ed25519_short:MOVI      R7,0
0x8400:                MOVI      R8,1
0x8404:                MOVI      R9,1
0x8408:                MOVI      R10,0
0x840c:                MOVI      R30,256
0x8410: spm_ed25519_short_loop:ROL       R28,R28
0x8414:                CSWAP     R7,R11
0x8418:                CSWAP     R8,R12
0x841c:                CSWAP     R9,R13
0x8420:                CSWAP     R10,R14
0x8424:                CALL      8370
0x8428:                CALL      83c0
0x842c:                CSWAP     R7,R11
0x8430:                CSWAP     R8,R12
0x8434:                CSWAP     R9,R13
0x8438:                CSWAP     R10,R14
0x843c:                SUBI      R30,R30,1
0x8440:                BRNZ      8410
0x8444:                RET       
0x8448: curve25519_point_generate:CALL      8710
0x844c:                GRV       R2
0x8450:                MOVI      R0,1537
0x8454:                ROR       R0,R0
0x8458:                HASH_IT   
0x845c:                HASH      R0,R0
0x8460:                LD        R31,12480
0x8464:                REDP      R0,R1,R0
0x8468: map_to_curve_elligator2_curve25519:MUL25519  R6,R0,R0
0x846c:                ADDP      R6,R6,R6
0x8470:                MOVI      R30,1
0x8474:                ADDP      R7,R6,R30
0x8478:                LD        R8,12768
0x847c:                MOVI      R30,0
0x8480:                SUBP      R9,R30,R8
0x8484:                MUL25519  R8,R8,R6
0x8488:                MUL25519  R10,R7,R7
0x848c:                MUL25519  R11,R10,R7
0x8490:                MUL25519  R8,R8,R9
0x8494:                ADDP      R8,R8,R10
0x8498:                MUL25519  R8,R8,R9
0x849c:                MUL25519  R12,R11,R11
0x84a0:                MUL25519  R10,R12,R12
0x84a4:                MUL25519  R12,R12,R11
0x84a8:                MUL25519  R12,R12,R8
0x84ac:                MUL25519  R10,R10,R12
0x84b0:                MOV       R1,R10
0x84b4:                CALL      8158
0x84b8:                MUL25519  R2,R2,R2
0x84bc:                MUL25519  R13,R2,R10
0x84c0:                MUL25519  R13,R13,R12
0x84c4:                LD        R30,12800
0x84c8:                MUL25519  R14,R13,R30
0x84cc:                MUL25519  R10,R13,R13
0x84d0:                MUL25519  R10,R10,R11
0x84d4:                SUBP      R4,R10,R8
0x84d8:                CMPA      ,R4,0
0x84dc:                BRNZ      84e8
0x84e0: curve25519_point_generate_y1_y11:MOV       R1,R11
0x84e4:                JMP       84f0
0x84e8: curve25519_point_generate_y1_y12:MOV       R1,R12
0x84ec:                JMP       84f0
0x84f0: curve25519_point_generate_y1_next:MUL25519  R2,R9,R6
0x84f4:                MUL25519  R3,R13,R0
0x84f8:                ORI       R4,R30,1
0x84fc:                MUL25519  R3,R3,R4
0x8500:                MUL25519  R4,R3,R30
0x8504:                MUL25519  R6,R8,R6
0x8508:                MUL25519  R10,R3,R3
0x850c:                MUL25519  R10,R10,R11
0x8510:                SUBP      R30,R10,R6
0x8514:                CMPA      ,R30,0
0x8518:                BRNZ      8524
0x851c: curve25519_point_generate_y2_y21:MOV       R0,R3
0x8520:                JMP       852c
0x8524: curve25519_point_generate_y2_y22:MOV       R0,R4
0x8528:                JMP       852c
0x852c: curve25519_point_generate_y2_next:MUL25519  R10,R1,R1
0x8530:                MUL25519  R10,R10,R11
0x8534:                SUBP      R30,R10,R8
0x8538:                CMPA      ,R30,0
0x853c:                BRNZ      8548
0x8540: curve25519_point_generate_xn_x1n:MOV       R3,R9
0x8544:                JMP       8550
0x8548: curve25519_point_generate_xn_x2n:MOV       R3,R2
0x854c:                JMP       8550
0x8550: curve25519_point_generate_xn_next:BRNZ      855c
0x8554: curve25519_point_generate_y_y1:MOV       R2,R1
0x8558:                JMP       8564
0x855c: curve25519_point_generate_y_y2:MOV       R2,R0
0x8560:                JMP       8564
0x8564: curve25519_point_generate_y_next:MOVI      R0,0
0x8568:                SUBP      R1,R0,R2
0x856c:                ANDI      R6,R2,1
0x8570:                XOR       R30,R30,R6
0x8574:                BRNZ      8580
0x8578: curve25519_point_generate_y_minus:MOV       R11,R1
0x857c:                JMP       8588
0x8580: curve25519_point_generate_y_plus:MOV       R11,R2
0x8584:                JMP       8588
0x8588: curve25519_point_generate_y_final:MOV       R10,R3
0x858c:                MOV       R1,R7
0x8590:                CALL      8220
0x8594:                MUL25519  R10,R10,R1
0x8598:                RET       
0x859c: eddsa_verify:  LD        R28,64
0x85a0:                LD        R31,12480
0x85a4:                LD        R6,12576
0x85a8:                LD        R11,12608
0x85ac:                LD        R12,12640
0x85b0:                MOVI      R13,1
0x85b4:                MUL25519  R14,R11,R12
0x85b8:                CALL      83fc
0x85bc:                ST        R7,256
0x85c0:                ST        R8,288
0x85c4:                ST        R9,320
0x85c8:                ST        R10,352
0x85cc: bp_eddsa_verify_sxb:LD        R24,160
0x85d0:                LD        R25,128
0x85d4:                LD        R26,96
0x85d8:                LD        R27,32
0x85dc:                SWE       R20,R24
0x85e0:                SWE       R21,R25
0x85e4:                SWE       R22,R26
0x85e8:                SWE       R23,R27
0x85ec:                HASH_IT   
0x85f0:                HASH      R28,R20
0x85f4:                MOVI      R3,128
0x85f8:                ROR8      R3,R3
0x85fc:                MOVI      R2,0
0x8600:                MOVI      R1,0
0x8604:                MOVI      R0,1024
0x8608:                HASH      R28,R0
0x860c:                SWE       R28,R28
0x8610:                SWE       R29,R29
0x8614: bp_eddsa_verify_after_hram:LD        R31,12512
0x8618:                REDP      R28,R28,R29
0x861c:                LD        R31,12480
0x8620:                MOV       R12,R26
0x8624:                CALL      826c
0x8628: bp_eddsa_verify_deca:CMPI      ,R1,0
0x862c:                BRNZ      867c
0x8630:                MOVI      R13,1
0x8634:                MUL25519  R14,R11,R12
0x8638:                CALL      83fc
0x863c: bp_eddsa_verify_exa:MOVI      R0,0
0x8640:                SUBP      R7,R0,R7
0x8644:                SUBP      R10,R0,R10
0x8648:                LD        R11,256
0x864c:                LD        R12,288
0x8650:                LD        R13,320
0x8654:                LD        R14,352
0x8658:                CALL      8370
0x865c:                MOV       R7,R11
0x8660:                MOV       R8,R12
0x8664:                MOV       R9,R13
0x8668:                CALL      8244
0x866c: bp_eddsa_verify_encq:LD        R31,12736
0x8670:                SUBP      R0,R27,R8
0x8674:                CMPA      ,R0,0
0x8678:                BRZ       8688
0x867c: eddsa_verify_fail:MOVI      R0,0
0x8680:                ST        R0,4128
0x8684:                END       
0x8688: eddsa_verify_success:MOVI      R0,1
0x868c:                ST        R0,4128
0x8690:                END       
0x8694: sha512_one_block:SWE       R3,R3
0x8698:                SWE       R2,R2
0x869c:                SWE       R1,R1
0x86a0:                SWE       R0,R0
0x86a4:                HASH      R4,R0
0x86a8:                RET       
0x86ac: sha512_init:   HASH_IT   
0x86b0:                MOVI      R0,0
0x86b4:                ST        R0,4096
0x86b8:                END       
0x86bc: sha512_update: LD        R3,32
0x86c0:                LD        R2,64
0x86c4:                LD        R1,96
0x86c8:                LD        R0,128
0x86cc:                CALL      8694
0x86d0:                MOVI      R0,0
0x86d4:                ST        R0,4096
0x86d8:                END       
0x86dc: sha512_final:  LD        R3,32
0x86e0:                LD        R2,64
0x86e4:                LD        R1,96
0x86e8:                LD        R0,128
0x86ec:                CALL      8694
0x86f0:                SWE       R4,R4
0x86f4:                SWE       R5,R5
0x86f8:                ST        R5,4128
0x86fc:                ST        R4,4160
0x8700:                HASH_IT   
0x8704:                MOVI      R0,0
0x8708:                ST        R0,4096
0x870c:                END       
0x8710: compose_exp_tag:MOVI      R3,84
0x8714:                ROL8      R3,R3
0x8718:                ORI       R3,R3,83
0x871c:                ROL8      R3,R3
0x8720:                ORI       R3,R3,1
0x8724:                ROL8      R3,R3
0x8728:                ORI       R3,R3,128
0x872c:                ROR8      R3,R3
0x8730:                RET       
