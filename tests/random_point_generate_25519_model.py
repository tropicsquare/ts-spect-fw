import binascii
import hashlib

p = 2**255 - 19
A = 486662

c1 = (p + 3) // 8       # Integer arithmetic
c2 = pow(2, c1, p)
c3 = pow(2, (p-1) // 4, p)
c4 = (p - 5) // 8       # Integer arithmetic
c5 = pow(-486664, c1, p) * c3 % p

def is_on_curve25519(x, y, z = 1):
    if z > 1:
        zinv = pow(z, p-2, p)
        x = x * zinv
        y = y * zinv
    return pow(y, 2, p) == (pow(x, 3, p) + A * pow(x, 2, p) + x) % p

def is_on_ed25519(x, y, z = 1):
    if z > 1:
        zinv = pow(z, p-2, p)
        x = x * zinv
        y = y * zinv
    return ( -pow(x, 2, p) + pow(y, 2, p) ) % p == 1 + ( ((-121665)*pow(121666, p-2, p)) * pow(x, 2, p) * pow(y, 2, p) ) % p 

def int2bytes(i) -> str:
    hex_string = '%x' % i
    n = len(hex_string)
    return binascii.unhexlify(hex_string.zfill(n + (n & 1)))

def cmov(a, b, c):
    #print("cmov: ", c)
    if not c:
        return a
    return b
    
def sgn0(x):
    return x % 2

def inv0(x):
    return pow(x, p-2, p)

def sha512(s):
    return hashlib.sha512(s).digest()

def expand_message(MSG: bytes, DST: bytes) -> bytes:
    EXP_TAG = int2bytes(0x8000000000000000000000000000000000000000000000000000000000545301)
    MSG = EXP_TAG + MSG + int2bytes(0x20) + DST + int2bytes(0x1E)
    return sha512(MSG)

def hash_to_field(MSG: str, DST: str) -> int:
    expanded = expand_message(MSG, DST)
    return int.from_bytes(expanded, 'big') % p

def map_to_curve_elligator2_curve25519(u):
    tv1 = pow(u, 2, p)
    tv1 = 2 * tv1 % p
    xd = tv1 + 1 % p        # Nonzero: -1 is square (mod p), tv1 is not
    x1n = -A  % p             # x1 = x1n / xd = -A / (1 + 2 * u^2)
    tv2 = pow(xd, 2, p)
    gxd = tv2 * xd  % p       # gxd = xd^3
    gx1 = A * tv1  % p        # x1n + A * xd
    gx1 = gx1 * x1n  % p      # x1n^2 + A * x1n * xd
    gx1 = gx1 + tv2  % p      # x1n^2 + A * x1n * xd + xd^2
    gx1 = gx1 * x1n  % p      # x1n^3 + A * x1n^2 * xd + x1n * xd^2
    tv3 = pow(gxd, 2, p)
    tv2 = pow(tv3, 2, p)           # gxd^4
    tv3 = tv3 * gxd % p       # gxd^3
    tv3 = tv3 * gx1 % p       # gx1 * gxd^3
    tv2 = tv2 * tv3 % p       # gx1 * gxd^7
    y11 = pow(tv2, c4, p)          # (gx1 * gxd^7)^((p - 5) / 8)
    y11 = y11 * tv3  % p       # gx1 * gxd^3 * (gx1 * gxd^7)^((p - 5) / 8)
    y12 = y11 * c3  % p
    tv2 = pow(y11, 2, p)
    tv2 = tv2 * gxd  % p
    e1 = tv2 == gx1
    y1 = cmov(y12, y11, e1)  # If g(x1) is square, this is its sqrt
    x2n = x1n * tv1  % p          # x2 = x2n / xd = 2 * u^2 * x1n / xd
    y21 = y11 * u  % p
    y21 = y21 * c2 % p
    y22 = y21 * c3 % p
    gx2 = gx1 * tv1  % p          # g(x2) = gx2 / gxd = 2 * u^2 * g(x1)
    tv2 = pow(y21, 2, p)
    tv2 = tv2 * gxd % p
    e2 = tv2 == gx2
    y2 = cmov(y22, y21, e2)  # If g(x2) is square, this is its sqrt
    tv2 = pow(y1, 2, p)
    tv2 = tv2 * gxd % p
    e3 = tv2 == gx1
    xn = cmov(x2n, x1n, e3)  # If e3, x = x1, else x = x2
    y = cmov(y2, y1, e3)    # If e3, y = y1, else y = y2
    e4 = sgn0(y) == 1        # Fix sign of y
    y = cmov(y, -y % p, e3 ^ e4)
    return (xn, xd, y, 1)

def point_generate_curve25519(DST: str, rng: int):
    m = int2bytes(rng)
    u = hash_to_field(m, DST)
    xn, xd, yn, yd = map_to_curve_elligator2_curve25519(u)
    x = xn * inv0(xd) % p
    y = yn * inv0(yd) % p
    x = xn
    z = xd
    y = yn * z % p
    return x, y, z

def map_to_edwards(xMn, xMd, yMn, yMd):
    xn = xMn * yMd % p
    xn = xn * c5 % p
    xd = xMd * yMn % p    # xn / xd = c1 * xM / yM
    yn = xMn - xMd % p
    yd = xMn + xMd % p   # (n / d - 1) / (n / d + 1) = (n - d) / (n + d)
    tv1 = xd * yd % p
    e = tv1 == 0
    if e:
        return (0, 1, 1, 1)
    return (xn, xd, yn, yd)

def point_generate_ed25519(DST: str, rng: int):
    m = int2bytes(rng)
    u = hash_to_field(m, DST)
    xMn, xMd, yMn, yMd = map_to_curve_elligator2_curve25519(u)
    xn, xd, yn, yd = map_to_edwards(xMn, xMd, yMn, yMd)
    xq = xn * pow(xd, p-2, p)
    yq = yn * pow(yd, p-2, p)
    x = xn * yd % p
    y = yn * xd % p
    z = xd * yd % p
    return (x, y, z)
