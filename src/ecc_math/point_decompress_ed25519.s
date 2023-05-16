;   https://datatracker.ietf.org/doc/rfc8032/
;
;   For advice on how to implement arithmetic modulo p = 2^255 - 19
;   efficiently and securely, see Curve25519 [CURVE25519].  For inversion
;   modulo p, it is recommended to use the identity x^-1 = x^(p-2) (mod
;   p).  Inverting zero should never happen, as it would require invalid
;   input, which would have been detected before, or would be a
;   calculation error.
;
;   For point decoding or "decompression", square roots modulo p are
;   needed.  They can be computed using the Tonelli-Shanks algorithm or
;   the special case for p = 5 (mod 8).  To find a square root of a,
;   first compute the candidate root x = a^((p+3)/8) (mod p).  Then there
;   are three cases:
;
;      x^2 = a (mod p).  Then x is a square root.
;
;      x^2 = -a (mod p).  Then 2^((p-1)/4) * x is a square root.
;
;      a is not a square modulo p.
;
;   1.  First, interpret the string as an integer in little-endian
;       representation.  Bit 255 of this number is the least significant
;       bit of the x-coordinate and denote this value x_0.  The
;       y-coordinate is recovered simply by clearing this bit.  If the
;       resulting value is >= p, decoding fails.
;
;   2.  To recover the x-coordinate, the curve equation implies
;       x^2 = (y^2 - 1) / (d y^2 + 1) (mod p).  The denominator is always
;       non-zero mod p.  Let u = y^2 - 1 and v = d y^2 + 1.  To compute
;       the square root of (u/v), the first step is to compute the
;       candidate root x = (u/v)^((p+3)/8).  This can be done with the
;       following trick, using a single modular powering for both the
;       inversion of v and the square root:
;
;                          (p+3)/8      3        (p-5)/8
;                 x = (u/v)        = u v  (u v^7)         (mod p)
;
;                 (p-5)/8 = 2^252 - 3
;
;   3.  Again, there are three cases:
;
;       1.  If v x^2 = u (mod p), x is a square root.
;
;       2.  If v x^2 = -u (mod p), set x <-- x * 2^((p-1)/4), which is a
;           square root.
;
;       3.  Otherwise, no square root exists for modulo p, and decoding
;           fails.
;
;   4.  Finally, use the x_0 bit to select the right square root.  If
;       x = 0, and x_0 = 1, decoding fails.  Otherwise, if x_0 != x mod
;       2, set x <-- p - x.  Return the decoded point (x,y).

; Expects:
;   Ed25519 prime in r31
;   Ed25519 parameter d in r6

; Input:
;   compressed point with Y coordinate in r12
; Output:
;   decompresd point (X, Y) = (r11, r12)
;
; Used registers (other than IN/OUT):
;   r0-5, r16-22

point_decompress_ed25519:
    MOV r16, r12
    LSL r16, r16
    BRC point_decompress_ed25519_x0_1
; point_decompress_ed25519_x0_0
    MOVI r22, 0     ; X0 = r22
    JMP point_decompress_ed25519_sqr
point_decompress_ed25519_x0_1:
    MOVI r22, 1
    JMP point_decompress_ed25519_sqr

point_decompress_ed25519_sqr:
    LSR r16, r16
    MOV r12, r16
    MUL25519 r16, r16, r16  ; r16 = y * y
    MOVI     r1,  1
    SUBP     r20, r16, r1   ; r20 = r16 - 1
    MUL25519 r16, r16, r6   ; r16 = r16 * r6
    ADDP     r21, r16, r1   ; r21 = r16 + 1
    
                            ; u = r20
                            ; v = r21

    MUL25519 r18, r21, r21  ; r18 = r21 * r21
    MUL25519 r18, r18, r21  ; r18 = r18 * r21   (r18 = v^3)

    MUL25519 r19, r18, r20  ; r19 = r18 * r20   (r19 = u*v^3)
    
    MUL25519 r18, r18, r18  ; r18 = r18 * r18
    MUL25519 r18, r18, r21  ; r18 = r18 * r21   (r18 = v^7)

    MUL25519 r1,  r18, r20  ; r1 = r18 * r20    (r1 = u*v^7)
    MOV      r16, r1        ; r16 = r1          (r16 = u*v^7)

    CALL inv_p25519_250     ; r2 = (u*v^7)^(2^250-1)

    MUL25519 r18, r2,  r2   ; r18 = r2 * r2     (r18 = (u*v^7)^(2^251-2))
    MUL25519 r18, r18, r18  ; r18 = r18 * r18   (r18 = (u*v^7)^(2^252-4))
    MUL25519 r18, r18, r16  ; r18 = r18 * r16   (r18 = (u*v^7)^(2^252-3) = (u*v^7)^((p-5)/8))

    MUL25519 r18, r18, r19  ; r18 = r18 * r19   (r18 = x = (u*v^3)(u*v^7)^((p-5)/8))

    MUL25519 r16, r18, r18  ; r16 = r18 * r18  (r16 = x^2)
    MUL25519 r16, r16, r21  ; r16 = r16 * r21  (r16 = v*x^2)

    LD       r1,  ca_eddsa_m1
    MUL25519 r17, r18, r1   ; r17 = r18 * ca_eddsa_m1

                            ; r16 = v * x^2
                            ; r17 = x * 2^((p-1)/4)
                            ; r18 = x
                            ; r20 = u

    SUBP     r19, r16, r20  ; r19 = r16 - r20   (r19 == 0 iff v*x^2 == u)
    ADDP     r20, r16, r20  ; r20 = r16 + r20   (r20 == 0 iff v*x^2 == -u)

    MOVI r1, 0              ; r1 = flag

; point_decompress_ed25519_vx2_check1
    CMPA r19, 0             ; v*x^2 == u
    BRNZ point_decompress_ed25519_vx2_check2
    MOV  r0, r18            ; res = x
    MOVI r1, 1
point_decompress_ed25519_vx2_check2:
    CMPA r20, 0             ; v*x^2 == -u
    BRNZ point_decompress_ed25519_vx2_check_flag
    MOV  r0, r17            ; res = x * 2^((p-1)/4)
    MOVI r1, 1
point_decompress_ed25519_vx2_check_flag:
    CMPI r1, 0
    BRZ  point_decompress_ed25519_fail

    MOVI r1, 0
; point_decompress_ed25519_check_x_is_0
    CMPA r0, 0
    BRNZ point_decompress_ed25519_check_X0_is_1
    ORI r1, r1, 1

point_decompress_ed25519_check_X0_is_1:
    CMPI r22, 1
    BRNZ point_decompress_ed25519_check_x_is_0_and_X0_is_1
    ORI r1, r1, 2

point_decompress_ed25519_check_x_is_0_and_X0_is_1:
    CMPI r1, 3
    BRZ point_decompress_ed25519_fail

; point_decompress_ed25519_add_parity
    MOVI r3, 0
    SUBP r3, r3, r0         ; r3 = -x
    ANDI r1, r0, 1          ; r1 = x mod 2
    CMP r1, r22             ; x mod 2 == x0
    BRZ point_decompress_ed25519_x_is_p_minus_x
    MOV r11, r0
    JMP point_decompress_ed25519_success

point_decompress_ed25519_x_is_p_minus_x:
    MOV r11, r3
    JMP point_decompress_ed25519_success

point_decompress_ed25519_success:
    MOVI r1, 1
    RET

point_decompress_ed25519_fail: 
    MOVI r1, 0
    RET
