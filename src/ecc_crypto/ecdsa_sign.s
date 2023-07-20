; ECDSA P-256 Sign
;
; Input:
;   Private Key part d in r24
;   Message Digest e in r25
;   Nonce k in r26
;
; Output:
;   ECDSA Signature (R,S) = (r9, r0)
;   Status in r30

ecdsa_sign:
    LD r26, ca_ecdsa_k

    LD r31, ca_q256
    GRV r27

    SCB r28, r26, r27

    CALL inv_q256

    LD r31, ca_p256
    LD r8, ca_p256_b

    LD r12, ca_p256_xG
    LD r13, ca_p256_yG
    MOVI r14, 1

    CALL spm_p256
    MOV r1, r11
    CALL inv_p256
    MUL256 r9, r9, r1
    MOVI r10, 0

    REDP r9, r10, r9


    CMPA r9, 0

.ifdef SPECT_ISA_VERSION_1
    CMPA    r9, 0
.endif

.ifdef SPECT_ISA_VERSION_2
    XORI    r30, r9,  0
.endif

    BRZ ecdsa_fail

    ST r9, 0x1000

    LD r31, ca_q256
    LD r24, ca_ecdsa_key
    LD r25, ca_ecdsa_msg_digest


    MULP r0, r24, r9
    ADDP r0, r0, r25
    MULP r0, r0, r26

.ifdef SPECT_ISA_VERSION_1
    CMPA    r0, 0
.endif

.ifdef SPECT_ISA_VERSION_2
    XORI    r30, r0,  0
.endif
    BRZ ecdsa_fail

    ST r0, 0x1020
    MOVI r0, 1
    ST r0, 0x1040
    END

ecdsa_fail:
    MOVI r0, 2
    ST r0, 0x1040
    END
