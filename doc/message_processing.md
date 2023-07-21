# SPECT Message Processing

In order to sign a message od arbitrary length (max 4096 bytes) using EdDSA, the message has to be streamed in to SPECT. The message is part of a byte string that is processed by TMAC or SHA-512 functions.

Let $M$ be a message and $n$ a length of the message in bytes. $M = "0, 1, ..., n-1"$.

We define $a||b$ as a concatenation of two strings:

$$"0_a, .., n_a-1" || "0_b, ..., n_b-1" = "0_a, .., n_a-1, b_0, ..., n_b-1"$$

We define $a^j$ as concatenation of $a$ $j$ times. E.g. $"0x01"^3 = "0x01, 0x01, 0x01"$

We define $to\_string(x)$ as big endian encoding of 16 bit unsigned integer x:

$$to\_string(0x3456) = "0x34, 0x56"$$

## Registers

SPECT works with 256 bit (or 32 byte) registers. Data to the registers data are loaded from memory by 4 byte words as $w_7 || w_6 || ... || w_1 || w_0$. One word is composed of 4 bytes as $"w_{x,3},w_{x,2},w_{x,1},w_{x,0}"$. One word can by also seen as an unsigned integer $w_{x,0} + w_{x,1} \times 2^{8} + w_{x,2} \times 2^{16} + w_{x,3} \times 2^{24}$.

Value in the register can be then interpreted as 256 bit unsigned integer : $r = w_{0,0} + w_{0,1} \times 2^{32} + w_{0,2} \times 2^{64} + ... + w_{7,3} \times 2^{223}$

## SHA-512

SPECT provides instruction for SHA-512 function. The instruction takes 4 32 byte registers (r0, r1, r2, r3), composes one 128 byte block of data as $r3 || r2 || r1 || r0$ and processes it with the SHA-512 function.

Let $M$ be a 210 byte message. $M = "M_0, M_1, ..., M_{208}, M_{209}"$.

After initialization of SHA-512 core, the message is then processed in two rounds of SHA-512 calculation. The first block is composed as:

$$r3 = "M_0, ..., M_{31}"$$
$$r2 = "M_{32}, ..., M_{63}"$$
$$r1 = "M_{64}, ..., M_{95}"$$
$$r0 = "M_{96}, ..., M_{127}"$$

When processing a last block of a message, we compose a padding $pad$ as follows:

$$j = 128 - byte\_len(last\_block) - 17$$
$$s = to\_string(bit\_len(M))$$
$$pad = "0x80" || "0x00"^{j+14} || s$$

In case of message $M$, $pad = "0x08" || "0x00"^{43} || "0x06, 0x90$

The second block is then composed as:

$$r3 = "M_{128}, ..., M_{159}"$$
$$r2 = "M_{160}, ..., M_{191}"$$
$$r1 = "M_{192}, ..., M_{209}" || "pad_0, ..., pad_{13}$$
$$r0 = "pad_{14}, ..., pad_{45}"$$


    NOTE: When j becomes negative, a new block is composed with j + 128.

## TMAC

SPECT provides instruction for TMAC as specified in [TMAC](TMAC.md). The instruction takes 18 LS bytes from register r and processes it with the TMAC function.

Let $M$ be a 34 byte message. $M = "M_0, M_1, ..., M_{32}, M_{33}"$.

The message is padded with the $10^*1$ padding to be a multiple of 18 bytes. The number of padding bytes is $q = 18 - (byte\_len(M) \pmod{18})$

| # Padding Bytes | Padded Message |
| - | - |
| $q = 0$ | $0x04\|\|0x00^{16}\|\|0x80$|
| $q = 1$ | $M\|\|0x84$ |
| $q = 2$ | $M\|\|0x04\|\|0x80$ |
| $q > 2$ | $M\|\|0x04\|\|0x00^{q-2}\|\|0x80$ |

After initialization of TMCA core (shares are loaded and initialization string is processed), the message is then processed in two rounds of TMAC calculation. The first block is composed as:

First block:
$$r = "0x00^{14}, M_0, ..., M_{17}"$$

Last block:
$$r = "0x00^{14}, M_{18}, ..., M_{33}, 0x04, 0x80"$$
