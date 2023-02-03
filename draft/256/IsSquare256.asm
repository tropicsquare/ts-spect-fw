_IsSquare256
; input :
;   Y2[r12]
; output
;   Y2^((p-1)/2) mod p_256 [r22]
; used registers :
;   {r0,r12,r22} ... r12 keeps value

;... bunch of MUL256 to calculate r22 <- Y2^((p-1)/2) ...