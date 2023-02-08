; ECDSA P-256 Sign
;
; Input:
;   Private Key d
;   Message Digest e
;   (random scalar k)
;
; Output:
;   ECDSA Signature (R,S) = (0x1000, 0x1020)
;   Status = 0x1040

ecdsa_sign:
    LD r26, c_scalar_addr

    LD r31, c_p256_q_addr
    LD r27, c_ed25519_xG_addr

    SCB r28, r26, r27

    CALL inv_q256

    LD r31, c_p256_addr
    LD r8, c_p256_b_addr

    LD r12, c_p256_xG_addr
    LD r13, c_p256_yG_addr
    MOVI r14, 1

    CALL spm_p256
    MOV r1, r11
    CALL inv_p256
    MUL256 r9, r9, r1
    MOVI r10, 0

    REDP r9, r10, r9

    CMPA r9, 0
    BRZ ecdsa_fail

    ST r9, 0x1000

    LD r31, c_p256_q_addr
    LD r24, c_key_addr
    LD r25, c_msg_digest_addr


    MULP r0, r24, r9
    ADDP r0, r0, r25
    MULP r0, r0, r26

    CMPA r26, 0
    BRZ ecdsa_fail

    ST r0, 0x1020
    MOVI r0, 1
    ST r0, 0x1040
    RET

ecdsa_fail:
    MOVI r0, 2
    ST r0, 0x1040
    RET
