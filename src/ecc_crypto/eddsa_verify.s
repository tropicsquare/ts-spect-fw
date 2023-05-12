;
; Inputs:
;   R part  : 0x0020-0x003F
;   S part  : 0x0040-0x005F
;   Pub key : 0x0060-0x007F
;   Pub key : 0x0080-0x00BF
;
; Outputs:
;   Fail/Success : 0x

; API Address Constants
ca_eddsa_verify_R   eq. 0x0020
ca_eddsa_verify_S   eq. 0x0040
ca_eddsa_verify_A   eq. 0x0060
ca_eddsa_verify_M1  eq. 0x0080
ca_eddsa_verify_M2  eq. 0x00A0
ca_eddsa_verify_res eq. 0x1000

; Internal Storage Address Constants
ca_eddsa_verify_internal_SBx eq. 0x0100
ca_eddsa_verify_internal_SBy eq. 0x0120
ca_eddsa_verify_internal_SBy eq. 0x0140
ca_eddsa_verify_internal_SBy eq. 0x0160

eddsa_verify:
    ; load and set needed parameters
    LD          r28, ca_eddsa_verify_S
    LD          r31, ca_eddsa_p
    LD          r6,  ca_eddsa_d
    LD          r11, ca_eddsa_xG
    LD          r12, ca_eddsa_yG
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    ; Q1 = S . B
    CALL        spm_ed25519_short
    ST          r7,  ca_eddsa_verify_internal_SBx
    ST          r8,  ca_eddsa_verify_internal_SBy
    ST          r9,  ca_eddsa_verify_internal_SBz
    ST          r10, ca_eddsa_verify_internal_SBt

    ; Load Rest of Inputs
    LD          r23, ca_eddsa_verify_M2
    LD          r24, ca_eddsa_verify_M1
    LD          r25, ca_eddsa_verify_A
    LD          r26, ca_eddsa_verify_R

    ; E = SHA512(ENC(R)||ENC(A)||M) mod q
    HASH_IT
    HASH        r28, r23

    MOVI        r3,  0x80
    ROR         r3,  r3
    MOVI        r1,  0
    MOVI        r2,  0
    MOVI        r0,  1024

    HASH        r28, r0

    LD          r31, ca_eddsa_q
    REDP        r28, r29, r28

    ; Decompress ENC(A)
    LD          r31, ca_eddsa_p
    MOV         r12, r25
    CALL        point_decopress_ed25519
    MOVI        r13, 1
    MUL25519    r14, r11, r12

    ; Q2 = E . A
    CALL        spm_ed25519_short

    ; Q = Q1 - Q2
    MOVI        r0,  0
    SUBP        r7,  r0,  r7
    SUBP        r10, r0,  r10

    LD          r11, ca_eddsa_verify_internal_SBx
    LD          r12, ca_eddsa_verify_internal_SBy
    LD          r13, ca_eddsa_verify_internal_SBz
    LD          r14, ca_eddsa_verify_internal_SBt

    CALL        point_add_ed25519
    MOV         r7,  r11
    MOV         r8,  r12
    MOV         r9,  r13

    ; ENC(Q)
    CALL        point_compress_ed25519

    ; ENC(Q) == ENC(R)
    SUBP        r0,  r26, r8
    CMPI        r0,  0
    BRZ         eddsa_verify_success
; eddsa_verify_fail
    MOVI        r0,  0
    ST          r0,  0x1000
    RET

eddsa_verify_success:
    MOVI        r0,  1
    ST          r0,  0x1000
    RET
