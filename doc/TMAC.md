# Tropic Message Authentication Code

TMAC uses KECCAK permutation function with $p = 400$ and $r = 18$. Thus size of one block of data to be processed is 18 bytes. Output size is 32 bytes.

$TMAC(K, X, N)$:

1. $initstr = (N||byte\_size(K)||K||0x00||0x00)$
2. $msgstr = (X||"00")$
3. $i = -bitlen(X)-2 \pmod{18}$
3. $pad = (10^{i}1)$
4. $fstring = (msgstr||pad)$
5. return $KECCAK(initstr||fstring)$

Padding $pad$ ensures, that the length of $fstring$ is multiple of 18 bytes.

Length of $initstr$ is $2 \times 18$ bytes.

# TMAC core

- $TMAC\_INIT(K, N)$ : initiates KECCAK core, compose $initstr$ and process it
- $TMAC\_UPDATE(msg\_chunk)$ : process one 18 bytes chunk of $fstring$

It is responsibility of a user to compose $fstring$ 

## TMAC in EdDSA nonce generation

- $K = \text{EdDSA pkey prefix}$
- $N = 0x0C$
- $X = (SCh||SCn||M)$

Secure Channel Hash $SCh$ is 32 bytes.

Secure Channel Nonce $SCn$ is 4 bytes.

Let $q = 18 - (byte\_len(M) \pmod{18})$.

Message $M$ is than padded as follows:

| $q$ | $pad$ |
| - | - |
| $q = 0$ | $0x04\|\|0x00^{16}\|\|0x80$|
| $q = 1$ | $M\|\|0x84$ |
| $q = 2$ | $M\|\|0x04\|\|0x80$ |
| $q > 2$ | $M\|\|0x04\|\|0x00^{q-2}\|\|0x80$|

## TMAC in ECDSA Key Setup

In ECDSA Key Setup, TMAC is used to generate second private key $w$.

- $K = d = k \pmod{q}$
- $N = 0x0A$
- $X = ""$

Empty message $X$ shall be padded with $pad = 0x04||0x00^{16}||0x80$

1. $TMAC\_INIT(d, 0x0A)$
2. $w = TMAC\_UPDATE(pad)$

## TMAC in ECDSA nonce generation

- $K = w$
- $N = 0x0B$
- $X = (SCh||SCn||z)$

Size of $z$ is fixed to 32 bytes, thus $pad$ is also fixed to $0x04||0x00^{2}||0x80$.

1. $TMAC\_INIT(w, 0x0B)$
2. $TMAC\_UPDATE(z[])
