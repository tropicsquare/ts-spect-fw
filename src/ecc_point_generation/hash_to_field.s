; Hash arbitrary 256-bit string in to an element of GF(2^255 - 19)
;
; The hashing function uses expand tag (EXP_TAG) and
; domain separator tag (DST) to separate use of the function
; in different contexts.
;
; See spect_fw/str2point.md for detailed description.
;
;   a = SHA512(EXP_TAG || x || 0x02 || DST || 0x1E) mod p
;
; Input:
;   x in r2
; Output:
;   a, an element of GF(2^255 - 19) in r0
; 
; Expects:
;   p in r31

hash_to_field:
    CALL    compose_exp_tag
    MOVI    r0,  0x601
    ROR     r0,  r0
    HASH_IT
    HASH    r0,  r0
    REDP    r0,  r1,  r0
    RET