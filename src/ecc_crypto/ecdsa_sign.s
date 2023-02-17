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
    LD r26, ca_ecdsa_k

    LD r31, ca_ecdsa_q
    GRV r27

    SCB r28, r26, r27

    CALL inv_q256

    LD r31, ca_ecdsa_p
    LD r8, ca_ecdsa_b

    LD r12, ca_ecdsa_xG
    LD r13, ca_ecdsa_yG
    MOVI r14, 1

    CALL spm_p256
    MOV r1, r11
    CALL inv_p256
    MUL256 r9, r9, r1
    MOVI r10, 0

    REDP r9, r10, r9

    CMPA r9, 0
    BRZ ecdsa_fail

<<<<<<< HEAD
=======
    LD r1, ca_ecdsa_r
    SUBP r1, r1, r9
    CMPA r1, 0
    BRNZ ecdsa_fail_r

>>>>>>> 9bbc909 (spect fw: add random data, directory reorganization)
    ST r9, 0x1000

    LD r31, ca_ecdsa_q
    LD r24, ca_ecdsa_key
    LD r25, ca_ecdsa_msg_digest


    MULP r0, r24, r9
    ADDP r0, r0, r25
    MULP r0, r0, r26

    CMPA r0, 0
    BRZ ecdsa_fail

<<<<<<< HEAD
=======
    LD r31, ca_ecdsa_p
    LD r1, ca_ecdsa_s
    SUBP r1, r1, r0
    CMPA r1, 0
    BRNZ ecdsa_fail_s

>>>>>>> 9bbc909 (spect fw: add random data, directory reorganization)
    ST r0, 0x1020
    MOVI r0, 1
    ST r0, 0x1040
    RET

ecdsa_fail:
    MOVI r0, 2
    ST r0, 0x1040
    RET
<<<<<<< HEAD
=======

ecdsa_fail_r:
    MOVI r0, 3
    ST r0, 0x1040
    RET

ecdsa_fail_s:
    MOVI r0, 4
    ST r0, 0x1040
    RET
>>>>>>> 9bbc909 (spect fw: add random data, directory reorganization)
