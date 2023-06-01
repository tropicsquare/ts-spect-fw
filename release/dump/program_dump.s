0x8000: _start:        LD        R0,0
0x8004:                CMPI      ,R0,81
0x8008:                BRNZ      8010
0x800c:                JMP       8634
0x8010: next_cmd_1:    CMPI      ,R0,82
0x8014:                BRNZ      801c
0x8018:                JMP       8644
0x801c: next_cmd_2:    CMPI      ,R0,83
0x8020:                BRNZ      8028
0x8024:                JMP       8664
0x8028: next_cmd_3:    CMPI      ,R0,74
0x802c:                BRNZ      8034
0x8030:                JMP       8524
0x8034: next_cmd_4:    END       
0x8038: inv_q256:      MULP      R2,R26,R26
0x803c:                MULP      R3,R2,R26
0x8040:                MULP      R4,R3,R3
0x8044:                MULP      R4,R4,R4
0x8048:                MULP      R5,R4,R3
0x804c:                MULP      R4,R5,R5
0x8050:                MULP      R4,R4,R4
0x8054:                MULP      R4,R4,R4
0x8058:                MULP      R4,R4,R4
0x805c:                MULP      R5,R4,R5
0x8060:                MULP      R4,R5,R5
0x8064:                MULP      R4,R4,R4
0x8068:                MOVI      R30,6
0x806c: inv_q256_loop_8:MULP      R4,R4,R4
0x8070:                MULP      R4,R4,R4
0x8074:                MULP      R4,R4,R4
0x8078:                SUBI      R30,R30,3
0x807c:                BRNZ      806c
0x8080:                MULP      R5,R4,R5
0x8084:                MULP      R4,R5,R5
0x8088:                MOVI      R30,15
0x808c: inv_q256_loop_16:MULP      R4,R4,R4
0x8090:                MULP      R4,R4,R4
0x8094:                MULP      R4,R4,R4
0x8098:                SUBI      R30,R30,3
0x809c:                BRNZ      808c
0x80a0:                MULP      R6,R4,R5
0x80a4:                MULP      R4,R6,R6
0x80a8:                MOVI      R30,63
0x80ac: inv_q256_loop_64:MULP      R4,R4,R4
0x80b0:                MULP      R4,R4,R4
0x80b4:                MULP      R4,R4,R4
0x80b8:                SUBI      R30,R30,3
0x80bc:                BRNZ      80ac
0x80c0:                MULP      R5,R4,R6
0x80c4:                MULP      R4,R5,R5
0x80c8:                MULP      R4,R4,R4
0x80cc:                MOVI      R30,30
0x80d0: inv_q256_loop_32:MULP      R4,R4,R4
0x80d4:                MULP      R4,R4,R4
0x80d8:                MULP      R4,R4,R4
0x80dc:                SUBI      R30,R30,3
0x80e0:                BRNZ      80d0
0x80e4:                MULP      R4,R4,R6
0x80e8:                LD        R5,576
0x80ec:                MOVI      R30,128
0x80f0: inv_q256_loop_lowpart:MULP      R4,R4,R4
0x80f4:                MULP      R4,R4,R4
0x80f8:                LSL       R5,R5
0x80fc:                BRC       8110
0x8100: inv_q256_loop_x0:LSL       R5,R5
0x8104:                BRNC      8124
0x8108: inv_q256_loop_x01:MULP      R4,R4,R26
0x810c:                JMP       8124
0x8110: inv_q256_loop_x1:LSL       R5,R5
0x8114:                BRC       8120
0x8118: inv_q256_loop_x10:MULP      R4,R4,R2
0x811c:                JMP       8124
0x8120: inv_q256_loop_x11:MULP      R4,R4,R3
0x8124: inv_q256_loop_lowpart_back:SUBI      R30,R30,2
0x8128:                BRNZ      80f0
0x812c:                MOV       R26,R4
0x8130:                RET       
0x8134: inv_p256:      MUL256    R3,R1,R1
0x8138:                MUL256    R4,R3,R1
0x813c:                MUL256    R3,R4,R4
0x8140:                MUL256    R3,R3,R3
0x8144:                MUL256    R2,R3,R4
0x8148:                MUL256    R3,R2,R2
0x814c:                MUL256    R3,R3,R3
0x8150:                MUL256    R3,R3,R3
0x8154:                MUL256    R3,R3,R3
0x8158:                MUL256    R3,R3,R2
0x815c:                MUL256    R3,R3,R3
0x8160:                MUL256    R3,R3,R3
0x8164:                MUL256    R5,R3,R4
0x8168:                MUL256    R3,R5,R5
0x816c:                MOVI      R30,9
0x8170: inv_p256_loop_10_1:MUL256    R3,R3,R3
0x8174:                SUBI      R30,R30,1
0x8178:                BRNZ      8170
0x817c:                MUL256    R3,R3,R5
0x8180:                MOVI      R30,10
0x8184: inv_p256_loop_10_2:MUL256    R3,R3,R3
0x8188:                MUL256    R3,R3,R3
0x818c:                SUBI      R30,R30,2
0x8190:                BRNZ      8184
0x8194:                MUL256    R5,R3,R5
0x8198:                MUL256    R3,R5,R5
0x819c:                MUL256    R3,R3,R3
0x81a0:                MUL256    R2,R3,R4
0x81a4:                MUL256    R3,R2,R2
0x81a8:                MUL256    R3,R3,R3
0x81ac:                MOVI      R30,30
0x81b0: inv_p256_loop_30_1:MUL256    R3,R3,R3
0x81b4:                MUL256    R3,R3,R3
0x81b8:                MUL256    R3,R3,R3
0x81bc:                SUBI      R30,R30,3
0x81c0:                BRNZ      81b0
0x81c4:                MUL256    R3,R3,R1
0x81c8:                MOVI      R30,128
0x81cc: inv_p256_loop_128:MUL256    R3,R3,R3
0x81d0:                MUL256    R3,R3,R3
0x81d4:                MUL256    R3,R3,R3
0x81d8:                MUL256    R3,R3,R3
0x81dc:                SUBI      R30,R30,4
0x81e0:                BRNZ      81cc
0x81e4:                MUL256    R3,R3,R2
0x81e8:                MOVI      R30,32
0x81ec: inv_p256_loop_32:MUL256    R3,R3,R3
0x81f0:                MUL256    R3,R3,R3
0x81f4:                MUL256    R3,R3,R3
0x81f8:                MUL256    R3,R3,R3
0x81fc:                SUBI      R30,R30,4
0x8200:                BRNZ      81ec
0x8204:                MUL256    R3,R3,R2
0x8208:                MOVI      R30,30
0x820c: inv_p256_loop_30_2:MUL256    R3,R3,R3
0x8210:                MUL256    R3,R3,R3
0x8214:                MUL256    R3,R3,R3
0x8218:                SUBI      R30,R30,3
0x821c:                BRNZ      820c
0x8220:                MUL256    R3,R3,R5
0x8224:                MUL256    R3,R3,R3
0x8228:                MUL256    R3,R3,R3
0x822c:                MUL256    R1,R3,R1
0x8230:                RET       
0x8234: inv_p25519_250:MUL25519  R2,R1,R1
0x8238:                MUL25519  R4,R2,R1
0x823c:                MUL25519  R3,R4,R4
0x8240:                MUL25519  R3,R3,R3
0x8244:                MUL25519  R2,R4,R3
0x8248:                MUL25519  R3,R2,R2
0x824c:                MUL25519  R3,R3,R3
0x8250:                MUL25519  R3,R3,R3
0x8254:                MUL25519  R3,R3,R3
0x8258:                MUL25519  R2,R2,R3
0x825c:                MUL25519  R3,R2,R2
0x8260:                MOVI      R30,7
0x8264: inv_p25519_loop_8:MUL25519  R3,R3,R3
0x8268:                SUBI      R30,R30,1
0x826c:                BRNZ      8264
0x8270:                MUL25519  R5,R2,R3
0x8274:                MUL25519  R3,R5,R5
0x8278:                MOVI      R30,15
0x827c: inv_p25519_loop_16_1:MUL25519  R3,R3,R3
0x8280:                SUBI      R30,R30,1
0x8284:                BRNZ      827c
0x8288:                MUL25519  R2,R5,R3
0x828c:                MUL25519  R3,R2,R2
0x8290:                MOVI      R30,15
0x8294: inv_p25519_loop_16_2:MUL25519  R3,R3,R3
0x8298:                SUBI      R30,R30,1
0x829c:                BRNZ      8294
0x82a0:                MUL25519  R2,R5,R3
0x82a4:                MUL25519  R2,R2,R2
0x82a8:                MUL25519  R2,R2,R2
0x82ac:                MUL25519  R5,R2,R4
0x82b0:                MUL25519  R3,R5,R5
0x82b4:                MOVI      R30,49
0x82b8: inv_p25519_loop_50_1:MUL25519  R3,R3,R3
0x82bc:                SUBI      R30,R30,1
0x82c0:                BRNZ      82b8
0x82c4:                MUL25519  R2,R5,R3
0x82c8:                MUL25519  R3,R2,R2
0x82cc:                MOVI      R30,99
0x82d0: inv_p25519_loop_100:MUL25519  R3,R3,R3
0x82d4:                SUBI      R30,R30,1
0x82d8:                BRNZ      82d0
0x82dc:                MUL25519  R2,R2,R3
0x82e0:                MUL25519  R3,R2,R2
0x82e4:                MOVI      R30,49
0x82e8: inv_p25519_loop_50_2:MUL25519  R3,R3,R3
0x82ec:                SUBI      R30,R30,1
0x82f0:                BRNZ      82e8
0x82f4:                MUL25519  R2,R3,R5
0x82f8:                RET       
0x82fc: inv_p25519:    CALL      8234
0x8300:                MUL25519  R3,R2,R2
0x8304:                MUL25519  R3,R3,R3
0x8308:                MUL25519  R3,R3,R1
0x830c:                MUL25519  R3,R3,R3
0x8310:                MUL25519  R3,R3,R3
0x8314:                MUL25519  R3,R3,R3
0x8318:                MUL25519  R1,R3,R4
0x831c:                RET       
0x8320: point_compress_ed25519:MOV       R1,R9
0x8324:                CALL      82fc
0x8328:                MUL25519  R7,R7,R1
0x832c:                MUL25519  R8,R8,R1
0x8330:                MOVI      R1,1
0x8334:                AND       R7,R7,R1
0x8338:                ROL       R8,R8
0x833c:                OR        R8,R8,R7
0x8340:                ROR       R8,R8
0x8344:                RET       
0x8348: point_decompress_ed25519:MOV       R16,R12
0x834c:                LSL       R16,R16
0x8350:                BRC       835c
0x8354:                MOVI      R22,0
0x8358:                JMP       8364
0x835c: point_decompress_ed25519_x0_1:MOVI      R22,1
0x8360:                JMP       8364
0x8364: point_decompress_ed25519_sqr:LSR       R16,R16
0x8368:                MOV       R12,R16
0x836c:                MUL25519  R16,R16,R16
0x8370:                MOVI      R1,1
0x8374:                SUBP      R20,R16,R1
0x8378:                MUL25519  R16,R16,R6
0x837c:                ADDP      R21,R16,R1
0x8380:                MUL25519  R18,R21,R21
0x8384:                MUL25519  R18,R18,R21
0x8388:                MUL25519  R19,R18,R20
0x838c:                MUL25519  R18,R18,R18
0x8390:                MUL25519  R18,R18,R21
0x8394:                MUL25519  R1,R18,R20
0x8398:                MOV       R16,R1
0x839c:                CALL      8234
0x83a0:                MUL25519  R18,R2,R2
0x83a4:                MUL25519  R18,R18,R18
0x83a8:                MUL25519  R18,R18,R16
0x83ac:                MUL25519  R18,R18,R19
0x83b0:                MUL25519  R16,R18,R18
0x83b4:                MUL25519  R16,R16,R21
0x83b8:                LD        R1,896
0x83bc:                MUL25519  R17,R18,R1
0x83c0:                SUBP      R19,R16,R20
0x83c4:                ADDP      R20,R16,R20
0x83c8:                MOVI      R1,0
0x83cc:                CMPA      ,R19,0
0x83d0:                BRNZ      83dc
0x83d4:                MOV       R0,R18
0x83d8:                MOVI      R1,1
0x83dc: point_decompress_ed25519_vx2_check2:CMPA      ,R20,0
0x83e0:                BRNZ      83ec
0x83e4:                MOV       R0,R17
0x83e8:                MOVI      R1,1
0x83ec: point_decompress_ed25519_vx2_check_flag:CMPI      ,R1,0
0x83f0:                BRZ       8444
0x83f4:                MOVI      R1,0
0x83f8:                CMPA      ,R0,0
0x83fc:                BRNZ      8404
0x8400:                ORI       R1,R1,1
0x8404: point_decompress_ed25519_check_X0_is_1:CMPI      ,R22,1
0x8408:                BRNZ      8410
0x840c:                ORI       R1,R1,2
0x8410: point_decompress_ed25519_check_x_is_0_and_X0_is_1:CMPI      ,R1,3
0x8414:                BRZ       8444
0x8418:                MOVI      R3,0
0x841c:                SUBP      R3,R3,R0
0x8420:                ANDI      R1,R0,1
0x8424:                CMP       ,R1,R22
0x8428:                BRZ       8434
0x842c:                MOV       R11,R0
0x8430:                JMP       843c
0x8434: point_decompress_ed25519_x_is_p_minus_x:MOV       R11,R3
0x8438:                JMP       843c
0x843c: point_decompress_ed25519_success:MOVI      R1,0
0x8440:                RET       
0x8444: point_decompress_ed25519_fail:MOVI      R1,1
0x8448:                RET       
0x844c: point_add_ed25519:SUBP      R0,R8,R7
0x8450:                SUBP      R1,R12,R11
0x8454:                MUL25519  R0,R0,R1
0x8458:                ADDP      R1,R8,R7
0x845c:                ADDP      R2,R12,R11
0x8460:                MUL25519  R1,R1,R2
0x8464:                MUL25519  R2,R10,R14
0x8468:                MUL25519  R2,R2,R6
0x846c:                ADDP      R2,R2,R2
0x8470:                MUL25519  R3,R9,R13
0x8474:                ADDP      R3,R3,R3
0x8478:                SUBP      R4,R1,R0
0x847c:                ADDP      R0,R1,R0
0x8480:                SUBP      R1,R3,R2
0x8484:                ADDP      R2,R3,R2
0x8488:                MUL25519  R11,R4,R1
0x848c:                MUL25519  R14,R4,R0
0x8490:                MUL25519  R12,R2,R0
0x8494:                MUL25519  R13,R2,R1
0x8498:                RET       
0x849c: point_dub_ed25519:MUL25519  R0,R7,R7
0x84a0:                MUL25519  R1,R8,R8
0x84a4:                MUL25519  R2,R9,R9
0x84a8:                ADDP      R2,R2,R2
0x84ac:                ADDP      R3,R0,R1
0x84b0:                ADDP      R4,R7,R8
0x84b4:                MUL25519  R4,R4,R4
0x84b8:                SUBP      R4,R3,R4
0x84bc:                SUBP      R0,R0,R1
0x84c0:                ADDP      R1,R2,R0
0x84c4:                MUL25519  R7,R4,R1
0x84c8:                MUL25519  R9,R0,R1
0x84cc:                MUL25519  R8,R0,R3
0x84d0:                MUL25519  R10,R4,R3
0x84d4:                RET       
0x84d8: spm_ed25519_short:MOVI      R7,0
0x84dc:                MOVI      R8,1
0x84e0:                MOVI      R9,1
0x84e4:                MOVI      R10,0
0x84e8:                MOVI      R30,256
0x84ec: spm_ed25519_short_loop:ROL       R28,R28
0x84f0:                CSWAP     R7,R11
0x84f4:                CSWAP     R8,R12
0x84f8:                CSWAP     R9,R13
0x84fc:                CSWAP     R10,R14
0x8500:                CALL      844c
0x8504:                CALL      849c
0x8508:                CSWAP     R7,R11
0x850c:                CSWAP     R8,R12
0x8510:                CSWAP     R9,R13
0x8514:                CSWAP     R10,R14
0x8518:                SUBI      R30,R30,1
0x851c:                BRNZ      84ec
0x8520:                RET       
0x8524: eddsa_verify:  LD        R28,64
0x8528:                LD        R31,704
0x852c:                LD        R6,800
0x8530:                LD        R11,832
0x8534:                LD        R12,864
0x8538:                MOVI      R13,1
0x853c:                MUL25519  R14,R11,R12
0x8540:                CALL      84d8
0x8544:                ST        R7,256
0x8548:                ST        R8,288
0x854c:                ST        R9,320
0x8550:                ST        R10,352
0x8554: bp_eddsa_verify_sxb:LD        R24,160
0x8558:                LD        R25,128
0x855c:                LD        R26,96
0x8560:                LD        R27,32
0x8564:                SWE       R20,R24
0x8568:                SWE       R21,R25
0x856c:                SWE       R22,R26
0x8570:                SWE       R23,R27
0x8574:                HASH_IT   
0x8578:                HASH      R28,R20
0x857c:                MOVI      R3,128
0x8580:                ROR8      R3,R3
0x8584:                MOVI      R2,0
0x8588:                MOVI      R1,0
0x858c:                MOVI      R0,1024
0x8590:                HASH      R28,R0
0x8594:                SWE       R28,R28
0x8598:                SWE       R29,R29
0x859c: bp_eddsa_verify_after_hram:LD        R31,736
0x85a0:                REDP      R28,R28,R29
0x85a4:                LD        R31,704
0x85a8:                MOV       R12,R26
0x85ac:                CALL      8348
0x85b0: bp_eddsa_verify_deca:CMPI      ,R1,0
0x85b4:                BRNZ      8604
0x85b8:                MOVI      R13,1
0x85bc:                MUL25519  R14,R11,R12
0x85c0:                CALL      84d8
0x85c4: bp_eddsa_verify_exa:MOVI      R0,0
0x85c8:                SUBP      R7,R0,R7
0x85cc:                SUBP      R10,R0,R10
0x85d0:                LD        R11,256
0x85d4:                LD        R12,288
0x85d8:                LD        R13,320
0x85dc:                LD        R14,352
0x85e0:                CALL      844c
0x85e4:                MOV       R7,R11
0x85e8:                MOV       R8,R12
0x85ec:                MOV       R9,R13
0x85f0:                CALL      8320
0x85f4: bp_eddsa_verify_encq:LD        R31,960
0x85f8:                SUBP      R0,R27,R8
0x85fc:                CMPA      ,R0,0
0x8600:                BRZ       8610
0x8604: eddsa_verify_fail:MOVI      R0,0
0x8608:                ST        R0,4128
0x860c:                END       
0x8610: eddsa_verify_success:MOVI      R0,1
0x8614:                ST        R0,4128
0x8618:                END       
0x861c: sha512_one_block:SWE       R3,R3
0x8620:                SWE       R2,R2
0x8624:                SWE       R1,R1
0x8628:                SWE       R0,R0
0x862c:                HASH      R4,R0
0x8630:                RET       
0x8634: sha512_init:   HASH_IT   
0x8638:                MOVI      R0,0
0x863c:                ST        R0,4096
0x8640:                END       
0x8644: sha512_update: LD        R3,32
0x8648:                LD        R2,64
0x864c:                LD        R1,96
0x8650:                LD        R0,128
0x8654:                CALL      861c
0x8658:                MOVI      R0,0
0x865c:                ST        R0,4096
0x8660:                END       
0x8664: sha512_final:  LD        R3,32
0x8668:                LD        R2,64
0x866c:                LD        R1,96
0x8670:                LD        R0,128
0x8674:                CALL      861c
0x8678:                SWE       R4,R4
0x867c:                SWE       R5,R5
0x8680:                ST        R5,4128
0x8684:                ST        R4,4160
0x8688:                HASH_IT   
0x868c:                MOVI      R0,0
0x8690:                ST        R0,4096
0x8694:                END       
