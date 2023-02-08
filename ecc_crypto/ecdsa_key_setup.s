; ECDSA P-256 Key Setup
;
; Input:
;
; Output:
;   Public Key  Q(x,y) = (0x1000, 0x1020)
;   Private Key d = 0x1040
;

ecdsa_key_setup:
    LD r28, c_key_addr
    ST r28, 0x1040

    LD r31, c_p256_q_addr
    LD r27, c_ed25519_xG_addr
    SCB r28, r28, r27

    LD r31, c_p256_addr
    LD r8, c_p256_b_addr

    LD r12, c_p256_xG_addr
    LD r13, c_p256_yG_addr
    MOVI r14, 1

    CALL spm_p256
    MOV r1, r11
    CALL inv_p256
    MUL256 r9, r9, r1
    MUL256 r10, r10, r1

    ST r9, 0x1000
    ST r10, 0x1020

    RET
    