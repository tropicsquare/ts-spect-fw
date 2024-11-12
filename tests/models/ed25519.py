#################################################################################
#   Source https://datatracker.ietf.org/doc/html/rfc8032#section-6
#################################################################################

## First, some preliminaries that will be needed.

import hashlib
from .tmac import tmac_int

def sha512(s):
    return hashlib.sha512(s).digest()

# Base field Z_p
p = 2**255 - 19

def modp_inv(x):
    return pow(x, p-2, p)

# Curve constant
d = -121665 * modp_inv(121666) % p

# Group order
q = 2**252 + 27742317777372353535851937790883648493

def sha512_modq(s):
    digest = sha512(s)
    return int.from_bytes(digest, "little") % q

## Then follows functions to perform point operations.

# Points are represented as tuples (X, Y, Z, T) of extended
# coordinates, with x = X/Z, y = Y/Z, x*y = T/Z

def point_add(P, Q):
    A, B = (P[1]-P[0]) * (Q[1]-Q[0]) % p, (P[1]+P[0]) * (Q[1]+Q[0]) % p;
    C, D = 2 * P[3] * Q[3] * d % p, 2 * P[2] * Q[2] % p;
    E, F, G, H = B-A, D-C, D+C, B+A;
    return (E*F, G*H, F*G, E*H);

# Computes Q = s * Q
def point_mul(s, P):
    Q = (0, 1, 1, 0)  # Neutral element
    while s > 0:
        if s & 1:
            Q = point_add(Q, P)
        P = point_add(P, P)
        s >>= 1
    return Q

def point_equal(P, Q):
    # x1 / z1 == x2 / z2  <==>  x1 * z2 == x2 * z1
    if (P[0] * Q[2] - Q[0] * P[2]) % p != 0:
        return False
    if (P[1] * Q[2] - Q[1] * P[2]) % p != 0:
        return False
    return True

## Now follows functions for point compression.

# Square root of -1
modp_sqrt_m1 = pow(2, (p-1) // 4, p)

# Compute corresponding x-coordinate, with low bit corresponding to
# sign, or return None on failure
def recover_x(y, sign):
    if y >= p:
        return None
    x2 = (y*y-1) * modp_inv(d*y*y+1)
    if x2 == 0:
        if sign:
            return None
        else:
            return 0

    # Compute square root of x2
    x = pow(x2, (p+3) // 8, p)
    if (x*x - x2) % p != 0:
        x = x * modp_sqrt_m1 % p
    if (x*x - x2) % p != 0:
        return None

    if (x & 1) != sign:
        x = p - x
    return x

# Base point
g_y = 4 * modp_inv(5) % p
g_x = recover_x(g_y, 0)
G = (g_x, g_y, 1, g_x * g_y % p)

def to_affine(P):
    zinv = modp_inv(P[2])
    x = P[0] * zinv % p
    y = P[1] * zinv % p

    return x, y

def point_compress(P):
    x, y = to_affine(P)
    return int.to_bytes(y | ((x & 1) << 255), 32, "little")

def point_decompress(s):
    if len(s) != 32:
        raise Exception("Invalid input length for decompression")
    y = int.from_bytes(s, "little")
    sign = y >> 255
    y &= (1 << 255) - 1

    x = recover_x(y, sign)
    if x is None:
        return None
    else:
        return (x, y, 1, x*y % p)

## These are functions for manipulating the private key.

def secret_expand(k: bytes):
    if len(k) != 32:
        raise Exception("Bad size of private key")
    h = sha512(k)
    s = int.from_bytes(h[:32], "little")
    s &= (1 << 254) - 8
    s |= (1 << 254)
    s = s % q
    prefix = int.from_bytes(h[32:], 'little')
    return s, prefix

def secret_to_public(s: int):
    return point_compress(point_mul(s, G))

def key_gen(k: bytes):
    s, prefix = secret_expand(k)
    A = secret_to_public(s)
    return s, prefix, A

## The signature function works as below.

def sign_standard(secret, msg):
    a, prefix = secret_expand(secret)
    prefix_bytes = prefix.to_bytes(32, 'little')
    A = point_compress(point_mul(a, G))
    r = sha512_modq(prefix_bytes + msg)
    R = point_mul(r, G)
    Rs = point_compress(R)
    h = sha512_modq(Rs + A + msg)
    s = (r + h * a) % q
    signature = Rs + int.to_bytes(s, 32, "little")
    return signature, A

def get_nonce(m: bytes, sch: bytes, scn: bytes, prefix: int):
    r1 = tmac_int(prefix, sch + scn + m, b"\x0C")
    r2 = tmac_int(r1, b"", b"\x0C")
    return (r1 | (r2 << 256)) % q

def sign(s: int, prefix: int, A: bytes, sch: bytes, scn: bytes, m: bytes) -> bytes:
    r = get_nonce(m, sch, scn, prefix)
    R = point_mul(r, G)
    Rs = point_compress(R)
    h = sha512_modq(Rs + A + m)
    S = (r + h * s) % q
    signature = Rs + int.to_bytes(S, 32, "little")
    return signature

## And finally the verification function.

def verify(A, m, signature):
    if len(A) != 32:
        raise Exception("Bad public key length")
    if len(signature) != 64:
        Exception("Bad signature length")
    A = point_decompress(A)
    if not A:
        return False
    Rs = signature[:32]
    R = point_decompress(Rs)
    if not R:
        return False
    S = int.from_bytes(signature[32:], "little")
    if S >= q: return False
    h = sha512_modq(Rs + A + m)
    sB = point_mul(S, G)
    hA = point_mul(h, A)
    return point_equal(sB, point_add(R, hA))