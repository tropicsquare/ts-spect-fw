_Sqrt256
; input :
;   Y2[r12]
; output :
;   sqrt(Y2)[r13]
; used registers
;   {r0, r12, r13} ... r12 keeps value

; ... bunch of MUL256 to compute r13 <- Y2^((p+1)/4) ...

    RET