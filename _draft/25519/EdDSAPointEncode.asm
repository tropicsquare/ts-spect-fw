_EdDSAPointEncode
; input :
;   P[r10,11]
; output :
;   ENC(P)[r12]
; used registers :
;   {r10..12}

    SWE r11 r11
    LSR r10 r10
    BRC EdDSAPointEncodeXzero
    
    ORI r11 r11 0x080
    RET
_EdDSAPointEncodeXzero
    ANDI r11 r11 0xF7F
    RET