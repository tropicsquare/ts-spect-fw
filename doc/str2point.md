# Encoding to Elliptic Curves

This is a summary of algorithms used in SPECT firmware to encode an arbitrary string to a point on an elliptic curve. It is based on https://datatracker.ietf.org/doc/draft-irtf-cfrg-hash-to-curve/. The algorithms are modified to a particular purposes in SPECT.

## Functions description

### sgn0

```
input: x, an element of GF(p)
output: 0 or 1

return x mod 2

```
### inv0

```
input: field element x of GF(p)
output: multiplicative inverse of x in the field or 0, iff x == 0

return x^(p-2)
```

### CMOV

```
CMOV(a, b, c): If c is False, CMOV returns a, otherwise it returns b.
```

### is_square
```
is_square(x) := { True,  iff x^((p - 1) / 2) is 0 or 1 in GF(p);
                { False, otherwise.
```

## Deterministic mapping

`(x, y) = map_to_curve(u)`

A mapping is a deterministic function from an element of the field F to a point on an elliptic curve E defined over GF(p). In general, the set of all points that a mapping can produce over all possible inputs may be only a subset of the points on the elliptic curve (i.e., the mapping may not be surjective). In addition, a mapping may output the same point for two or more distinct inputs (i.e., the mapping may not be injective). In general, the result of mapping is not uniform random point.

### Weierstrass Curve

`E_w : y^2 = g(x) = x^3 + A * x + B` in GF(p)

#### Preconditions

`A != 0` and `B != 0`

#### Constants

```
A and B, the parameters of the Weierstrass curve.

Z, an element of GF(p) meeting the below criteria.

    Z is non-square in GF(p),
    Z != -1 in GF(p),
    g(B / (Z * A)) is square in GF(p).
```

For NIST P-256 the recommended `Z` is -10

#### Exceptions

The exceptional cases for u occur when `Z^2 * u^4 + Z * u^2 == 0`. Implementations must detect this case and set `x_1 = B / (Z * A)`, which guarantees that `g(x1)` is square by the condition on `Z` given above.

#### Operations

**map_to_curve_simple_swu(u)**

```
Input: u, an element of GF(p).
Output: (x, y), a point on E.

Steps:
1.  tv1 = u^2
2.  tv1 = Z * tv1
3.  tv2 = tv1^2
4.  tv2 = tv2 + tv1
5.  tv3 = tv2 + 1
6.  tv3 = B * tv3
7.  tv4 = CMOV(Z, -tv2, tv2 != 0)
8.  tv4 = A * tv4
9.  tv2 = tv3^2
10. tv6 = tv4^2
11. tv5 = A * tv6
12. tv2 = tv2 + tv5
13. tv2 = tv2 * tv3
14. tv6 = tv6 * tv4
15. tv5 = B * tv6
16. tv2 = tv2 + tv5
17.   x = tv1 * tv3
18. (is_gx1_square, y1) = sqrt_ratio(tv2, tv6)
19.   y = tv1 * u
20.   y = y * y1
21.   x = CMOV(x, tv3, is_gx1_square)
22.   y = CMOV(y, y1, is_gx1_square)
23.  e1 = sgn0(u) == sgn0(y)
24.   y = CMOV(-y, y, e1)
25.   x = x / tv4
26. return (x, y)
```

**sqrt_ratio_3mod4(u, v)**

```
Parameters:
- GF(p), a finite field of characteristic p and order q = p^m,
  where q = 3 mod 4.
- Z, the constant from the simplified SWU map.

Input: u and v, elements of GF(p), where v != 0.
Output: (b, y), where
  b = True and y = sqrt(u / v) if (u / v) is square in GF(p), and
  b = False and y = sqrt(Z * (u / v)) otherwise.

Constants:
1. c1 = (q - 3) / 4     # Integer arithmetic
2. c2 = sqrt(-Z)

Procedure:
1. tv1 = v^2
2. tv2 = u * v
3. tv1 = tv1 * tv2
4. y1 = tv1^c1
5. y1 = y1 * tv2
6. y2 = y1 * c2
7. tv3 = y1^2
8. tv3 = tv3 * v
9. isQR = tv3 == u
10. y = CMOV(y2, y1, isQR)
11. return (isQR, y)
```

### Montgomery Curve

`B * y^2 = x^3 + A * x^2 + x`

#### Preconditions

`A != 0`, `B != 0`, and `(A^2 - 4) / B^2` is non-zero and non-square in GF(p).

#### Constants

```
Parameters A and B

Z a non-square element of GF(p)
```

For Curve25519 the recommended `Z` is 2

#### Exceptions

No exceptions for `p = 2^255 - 19` in case of Curve25519

#### Operations

**map_to_curve_elligator2_curve25519(u)**

```
Input: u, an element of GF(p).
Output: (xn, xd, yn, yd) such that (xn / xd, yn / yd) is a
        point on curve25519.

Constants:
1. c1 = (q + 3) / 8       # Integer arithmetic
2. c2 = 2^c1
3. c3 = sqrt(-1)
4. c4 = (q - 5) / 8       # Integer arithmetic

Steps:
1.  tv1 = u^2
2.  tv1 = 2 * tv1
3.   xd = tv1 + 1         # Nonzero: -1 is square (mod p), tv1 is not
4.  x1n = -A              # x1 = x1n / xd = -A / (1 + 2 * u^2)
5.  tv2 = xd^2
6.  gxd = tv2 * xd        # gxd = xd^3
7.  gx1 = A * tv1         # x1n + A * xd
8.  gx1 = gx1 * x1n       # x1n^2 + A * x1n * xd
9.  gx1 = gx1 + tv2       # x1n^2 + A * x1n * xd + xd^2
10. gx1 = gx1 * x1n       # x1n^3 + A * x1n^2 * xd + x1n * xd^2
11. tv3 = gxd^2
12. tv2 = tv3^2           # gxd^4
13. tv3 = tv3 * gxd       # gxd^3
14. tv3 = tv3 * gx1       # gx1 * gxd^3
15. tv2 = tv2 * tv3       # gx1 * gxd^7
16. y11 = tv2^c4          # (gx1 * gxd^7)^((p - 5) / 8)
17. y11 = y11 * tv3       # gx1 * gxd^3 * (gx1 * gxd^7)^((p - 5) / 8)
18. y12 = y11 * c3
19. tv2 = y11^2
20. tv2 = tv2 * gxd
21.  e1 = tv2 == gx1
22.  y1 = CMOV(y12, y11, e1)  # If g(x1) is square, this is its sqrt
23. x2n = x1n * tv1           # x2 = x2n / xd = 2 * u^2 * x1n / xd
24. y21 = y11 * u
25. y21 = y21 * c2
26. y22 = y21 * c3
27. gx2 = gx1 * tv1           # g(x2) = gx2 / gxd = 2 * u^2 * g(x1)
28. tv2 = y21^2
29. tv2 = tv2 * gxd
30.  e2 = tv2 == gx2
31.  y2 = CMOV(y22, y21, e2)  # If g(x2) is square, this is its sqrt
32. tv2 = y1^2
33. tv2 = tv2 * gxd
34.  e3 = tv2 == gx1
35.  xn = CMOV(x2n, x1n, e3)  # If e3, x = x1, else x = x2
36.   y = CMOV(y2, y1, e3)    # If e3, y = y1, else y = y2
37.  e4 = sgn0(y) == 1        # Fix sign of y
38.   y = CMOV(y, -y, e3 XOR e4)
39. return (xn, xd, y, 1)
```

### Twisted Edwards Curve

Reuse of mapping to related Montgomery Curve and then applying rational mapping.

#### Rational Mapping from Curve25519

`(x, y) = (sqrt(-486664)*u/v, (u-1)/(u+1))`

#### Operations

**map_to_curve_elligator2_edwards25519(u)**

```
Input: u, an element of GF(p).
Output: (xn, xd, yn, yd) such that (xn / xd, yn / yd) is a
        point on edwards25519.

Constants:
1. c1 = sqrt(-486664) # sgn0(c1) MUST equal 0

Steps:
1.  (xMn, xMd, yMn, yMd) = map_to_curve_elligator2_curve25519(u)
2.  xn = xMn * yMd
3.  xn = xn * c1
4.  xd = xMd * yMn    # xn / xd = c1 * xM / yM
5.  yn = xMn - xMd
6.  yd = xMn + xMd    # (n / d - 1) / (n / d + 1) = (n - d) / (n + d)
7. tv1 = xd * yd
8.   e = tv1 == 0
9.  xn = CMOV(xn, 0, e)
10. xd = CMOV(xd, 1, e)
11. yn = CMOV(yn, 1, e)
12. yd = CMOV(yd, 1, e)
13. return (xn, xd, yn, yd)
```

## Square roots

### For q = 5(mod 8)

```
sqrt_5mod8(x)

Parameters:
- GF(p), a finite field of characteristic p and order q = p^m.

Input: x, an element of GF(p).
Output: z, an element of GF(p) such that (z^2) == x, if x is square in GF(p).

Constants:
1. c1 = sqrt(-1) in GF(p), i.e., (c1^2) == -1 in GF(p)
2. c2 = (q + 3) / 8     # Integer arithmetic

Procedure:
1. tv1 = x^c2
2. tv2 = tv1 * c1
3.   e = (tv1^2) == x
4.   z = CMOV(tv2, tv1, e)
5. return z
```

### For q = 3(mod 4)

```
sqrt_3mod4(x)

Parameters:
- GF(p), a finite field of characteristic p and order q = p^m.

Input: x, an element of GF(p).
Output: z, an element of GF(p) such that (z^2) == x, if x is square in GF(p).

Constants:
1. c1 = (q + 1) / 4     # Integer arithmetic

Procedure:
1. return x^c1
```
