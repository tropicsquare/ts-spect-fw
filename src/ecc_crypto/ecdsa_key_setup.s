; ECDSA P-256 Key Setup
;
; Input:
;
; Output:
;   Public Key  Q(x,y) = (0x1000, 0x1020)
;   Private Key d = 0x1040
;

ecdsa_key_setup:
    LD r28, ca_ecdsa_key
    ST r28, 0x1040

    LD r31, ca_ecdsa_q
    GRV r27
    SCB r28, r28, r27

    LD r31, ca_ecdsa_p
    LD r8, ca_ecdsa_b

    LD r12, ca_ecdsa_xG
    LD r13, ca_ecdsa_yG
    MOVI r14, 1

    CALL spm_p256
    MOV r1, r11
    CALL inv_p256
    MUL256 r9, r9, r1
    MUL256 r10, r10, r1

    ST r9, 0x1000
    ST r10, 0x1020

    END
    