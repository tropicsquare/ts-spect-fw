; Fully masked and randomized X25519 algorithm
;
; Inputs:
;   X25519 Public Key u in r16
;   X25519 Private Key k in r19
;   DST_ID for point generation in r0
;
;   1) Random Projective Coordinates -- (x, 1) == (r * x, r)
;   2) Group Scalar Randomization -- k = k + r * #E (mod p)
;   3) Point Splitting -- k.P1 = k.P2 + k.P3 for P = P1 + P2
;
; Full algorithm:
;    1) Compute P1.y from P1.x
;    2) Randomize P1.z
;    3) Mask the scalar s as s2 = s + r2 * #E
;    4) Generate random point P2 (See str2point.md)
;    5) Compute sP2.x = s2.P2
;    6) Recover sP2.y
;    7) Compute P3 = P2 + P1
;    8) Mask scalar s as s3 = s + r3 * #E
;    9) Compute sP3.x = s3.P3
;   10) Recover sP3.y
;   11) Compute sP1 = sP2 - sP3
;   12) Transform sP1.x to affine coordinate system
;
; Intemediate values:
;   P1 = (r16, r17, r18)
;   P2 = 
;   P3 =
;   k 

x25519_full_masked:
    LD          r31, ca_p25519
;    1) Compute P1.y from P1.x
    CALL        get_y_curve25519
;    2) Randomize P1.z
    GRV         r18
    MUL25519    r16, r16, r18
    MUL25519    r17, r17, r18
;    3) Mask the scalar s as s2 = s + r2 * #E
    GRV         r30
    LD          r31, ca_p8q25519
    SCB         r28, r19, r30
;    4) Generate random point P2
    LD          r31, ca_p25519
    LD          r1, ca_dst_template
    OR          r1, r1, r0
    ROL8        r1, r1
    CALL        ed25519_point_generate
;    5) Compute sP2 = s2.P2
    CALL        spm_curve25519
;    6) Recover sP2.y
    CALL        y_recovery_curve25519
