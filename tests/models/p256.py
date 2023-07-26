import hashlib
import random as rn

from .tmac import tmac

p = 2**256 - 2**224 + 2**192 + 2**96 - 1
q = 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551
xG = 0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296
yG = 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5
a = p - 3

def sha256(m):
    return int(hashlib.sha256(m).hexdigest(),16)

def shift(x, i):
    return (x >> i) & 1

def inv0(x, mod=p):
    return pow(x, mod-2, mod)

def ec_add(x1, y1, x2, y2):
    if x1 == 0 and y1 == 0:
        return x2, y2
    if x2 == 0 and y2 == 0:
        return x1, y1

    r0 = (y2 - y1) % p
    r1 = (x2 - x1) % p
    lmbd = (r0 * inv0(r1)) % p
    x3 = (lmbd * lmbd - x1 - x2) % p
    y3 = (lmbd * (x1 - x3) - y1) % p
    return x3, y3

def ec_dub(x1, y1):
    if x1 == 0 and y1 == 0:
        return 0, 0
    r0 = (3*x1*x1 + a) % p
    r1 = (2*y1) % p
    lmbd = (r0 * inv0(r1)) % p
    x3 = (lmbd * lmbd - x1 - x1) % p
    y3 = (lmbd * (x1 - x3) - y1) % p
    return x3, y3

def spm(k, x, y):
    xQ = 0
    yQ = 0

    for i in range(255, -1, -1):
        xQ, yQ = ec_dub(xQ, yQ)
        if shift(k, i):
            xQ, yQ = ec_add(xQ, yQ, xG, yG)
    
    return xQ, yQ

def key_gen(k):
    d = int.from_bytes(k, 'little') % p
    db = d.to_bytes(32, 'little')
    w = tmac(db, b"", b"\x0A")
    Ax, Ay = spm(d, xG, yG)
    return d, w, Ax, Ay

def sign(d, w, sch, scn, z):
    #print("tmac msg:", (sch + scn + z).hex())
    k = tmac(w, sch + scn + z, b"\x0B")
    k_int = int.from_bytes(k, byteorder="big") % q

    #print("sign, k_int:", hex(k_int))

    if k_int == 0:
        print("Test Model: k_int = 0. ECDSA Failed.")

    x, y = spm(k_int, xG, yG)
    #print("sign, x:", hex(x))
    #print("sign, y:", hex(y))
    r = x % q

    if r == 0:
        print("Test Model: r = 0. ECDSA Failed.")

    z_int = int.from_bytes(z, 'big')

    s = ((z_int + d*r) * inv0(k_int, q)) % q

    return r, s


