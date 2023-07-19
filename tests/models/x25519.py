p = 2**255 - 19

a24M = 121665

def inv0(z):
    return pow(z, p-2, p)

def cswap(swap, x_2, x_3):
    dummy = swap * ((x_2 - x_3) %p)
    x_2 = x_2 - dummy
    x_2 %=p
    x_3 = x_3 + dummy
    x_3 %=p
    return (x_2, x_3)

def int2scalar(x: int) -> int:
    tmp = x
    tmp &= ~(2**255 + 7)
    tmp |= 2**254
    return tmp

def bytes2scalar(b: bytes) -> int:
    tmp = int.from_bytes(b, 'little')
    tmp &= ~(2**255 + 7)
    tmp |= 2**254
    return tmp

def x25519(k, u):
    x_1 = u
    x_2 = 1
    z_2 = 0
    x_3 = u
    z_3 = 1
    swap = 0

    for t in reversed(range(255)):
        k_t = (k >> t) & 1
        swap ^= k_t
        x_2, x_3 = cswap(swap, x_2, x_3)
        z_2, z_3 = cswap(swap, z_2, z_3)
        swap = k_t

        A = x_2 + z_2
        A %=p

        AA = A * A
        AA %=p

        B = x_2 - z_2
        B %=p

        BB = B * B
        BB %=p

        E = AA - BB
        E %=p

        C = x_3 + z_3
        C %=p

        D = x_3 - z_3
        D %=p

        DA = D * A
        DA %=p

        CB = C * B
        CB %=p

        x_3 = ((DA + CB) %p)**2
        x_3 %=p

        z_3 = x_1 * (((DA - CB) %p)**2) %p
        z_3 %=p

        x_2 = AA * BB
        x_2 %=p

        z_2 = E * ((AA + (a24M * E) %p) %p)
        z_2 %=p

    x_2, x_3 = cswap(swap, x_2, x_3)
    z_2, z_3 = cswap(swap, z_2, z_3)

    return (x_2 * inv0(z_2)) % p