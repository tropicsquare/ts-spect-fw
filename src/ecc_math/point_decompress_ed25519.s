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
;   Ed25519 prime in e31
;   Ed25519 parameter d in r6

; Input:
;   compressed point with Y coordinate

point_decopress_ed25519:
    ; r16 = y * y
    ; r20 = r16 - 1
    ; r16 = r16 * r6
    ; r16 = r16 + 1
    
    ; u = r20, v = r16

    ; r18 = r16 * r16
    ; r18 = r18 * r16   (r18 = v^3)

    ; r19 = r18 * r20   (r19 = u*v^3)
    
    ; r18 = r18 * r18
    ; r18 = r18 * r16   (r18 = v^7)

    ; r1 = r18 * r20    (r1 = u*v^7)
    ; r16 = r1

    CALL inv_p25519_250

    ; r18 = r2 * r2
    ; r18 = r18 * r18
    ; r18 = r18 * r16  (r18 = (u*v^7)^((p-5)/8))
    ; r18 = r18 * r19  (r18 = (u*v^3)(u*v^7)^((p-5)/8) = x)

    ; r16 = r18 * r18  (r16 = x^2)

    ; r17 = r18 * ca_eddsa_m1

    ; r19 = r16 - r20
    ; r20 = r16 + r20

    CMPA r19, 0
    BRZ point_decopress_ed25519_case1

    CMPA r20, 0
    BRZ point_decopress_ed25519_case2

    ; fail

point_decopress_ed25519_case1:
    CMPA r20, 0
    BRZ point_decopress_ed25519_case2
    MOV r0, r16
    JMP point_decopress_ed25519_success

point_decopress_ed25519_case2:
    MOV r0, r17
    JMP point_decopress_ed25519_success

point_decopress_ed25519_success:
    MOVI r1, 1
    RET

point_decopress_ed25519_fail: 
    MOVI r1, 0
    RET
