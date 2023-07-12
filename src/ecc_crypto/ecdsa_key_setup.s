; ECDSA P-256 Key Setup
;
; Input:
;   seed k in r16
;
; Output:
;   Public Key  A(x,y) = r9, r10
;   Private Key d = r16
;   Private Key w = r17
;   Success = r1 - (ok: 0, fail: 1)

ecdsa_key_setup:
    LD r31, ca_ecdsa_q

    MOVI    r1,  0
    RETP    r16, r29, r16

.ifdef SPECT_ISA_VERSION_1
    CMPA    r16, 0
.endif

.ifdef SPECT_ISA_VERSION_2
    XOR     r1,  r1,  r16
.endif

    BRZ ecdsa_key_setup_fail

.ifdef SPECT_ISA_VERSION_1
    MOVI    r17, 0
.endif

.ifdef SPECT_ISA_VERSION_2
; possible need of 4 GRV
    TMAC_IT r0
    TMAC_IS r16, 0xA

    MOVI    r2,  0x04
    MOVI    r30, 17
ecdsa_key_setup_tmac_padding_loop:
    ROL8    r2,  r2
    SUBI    r30, r30, 1
    BRNZ    ecdsa_key_setup_tmac_padding_loop

    TMAC_UP r2
    TMAC_RD r17
.endif

    GRV     r27
    SCB     r28, r16, r27

    LD      r31, ca_ecdsa_p
    LD      r8, ca_ecdsa_b

    LD      r12, ca_ecdsa_xG
    LD      r13, ca_ecdsa_yG
    MOVI    r14, 1

    CALL    spm_p256
    MOV     r1, r11
    CALL    inv_p256
    MUL256  r9, r9, r1
    MUL256  r10, r10, r1
    
    MOVI    r1, 0

    RET
    
ecdsa_key_setup_fail:
    MOVI    r1,  1
    RET