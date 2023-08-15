; ==============================================================================
;  file    
;  author  vit.masek@tropicsquare.com
;  license TODO
; ==============================================================================
;
; Compress Ed25519 point in extended coordinates
; Based on https://datatracker.ietf.org/doc/rfc8032/ Section 5.1.2
;
; Input:
;               X    Y    Z
;   Point P = (r7,  r8,  r9)
;
; Output:
;   Compressed point Q = ENC(P) in r8
;
; ==============================================================================

point_compress_ed25519:
    MOV         r1,  r9
    CALL        inv_p25519
    MUL25519    r7,  r7,  r1
    MUL25519    r8,  r8,  r1
    MOVI        r1,  1
    AND         r7,  r7,  r1
    ROL         r8,  r8
    OR          r8,  r8,  r7
    ROR         r8,  r8
    SWE         r8,  r8
    RET