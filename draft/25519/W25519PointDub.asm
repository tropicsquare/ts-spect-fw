_W25519PointDub
; input :
;   Q[r8,9,10]
; output :
;   2*Q[r14,15,16]
; used registers
;   {r0...16, r31}

; ... MUL25519, ADDP, SUBP, LD ...