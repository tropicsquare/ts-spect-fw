# SPECT Message Processing

In order to sign a message od arbitrary length (max 4096 bytes) using EdDSA, the message has to be streamed in to SPECT. The message is part of a byte string that is processed by TMAC or SHA-512 functions.

Let $M$ be a message and $n$ a length of the message in bytes. $M = "b_0, b_1, ..., b_{n-1}"$.

We define $x||y$ as a concatenation of two strings:

$$"x_0, .., x_{n-1}" || "y_0, ..., y_{n-1}" = "x_0, .., x_{n-1}, y_0, ..., y_{n-1}"$$

We define $a^j$ as concatenation of $a$ $j$ times. E.g. $"0x01"^3 = "0x01, 0x01, 0x01"$

We define $to\_string(x)$ as big-endian encoding of unsigned integer x. E.g. $to\_string(0x3456) = "x34, x56"$

## Registers

SPECT works with 256 bit (or 32 byte) registers. Data to the registers are loaded from memory by 4 byte words as $w_7 || w_6 || ... || w_1 || w_0$. One word is composed of 4 bytes as $"w_{x,3},w_{x,2},w_{x,1},w_{x,0}"$. One word can by also seen as an unsigned integer $w_{x,0} + w_{x,1} \times 2^{8} + w_{x,2} \times 2^{16} + w_{x,3} \times 2^{24}$.

Value in the register can be then interpreted as 256 bit unsigned integer : $r = w_{0,0} + w_{0,1} \times 2^{32} + w_{0,2} \times 2^{64} + ... + w_{7,3} \times 2^{223}$

This way, SPECT naturally interprets received bytes as little-endian encoded integer. However, endianity of the original string is switched this way.

**Original string:**
$$"x00, x01, x02, ..., x1D, x1E, x1F"$$

**Words:**
$$w_0 = "x03, x02, x01, x00"$$
$$...$$
$$w_7 = "x1F, x1E, x1D, x1C"$$

**Integer:**
$$0x1F1E1D1C ... 03020100$$

**Register as string**
$$x1F, x1E, x1D, ..., x02, x01, 0x00$$

## SHA-512

SPECT provides instructions for SHA-512 function - `HASH_IT` and `HASH`. The instruction takes 4 32-byte registers (r0, r1, r2, r3), composes one 128 byte block of data as $r3 || r2 || r1 || r0$ and processes it with the SHA-512 function. In order to pass the data in the right order, SPECT FW must execute `SWE` instruction on the registers before passing the values to `HASH` instruction.

Let $M$ be a 210 byte message. $M = "M_0, M_1, ..., M_{208}, M_{209}"$.

After initialization of SHA-512 core, the message is then processed in two rounds of SHA-512 calculation. The first block is composed as:

$$r3 = "M_0, ..., M_{31}"$$
$$r2 = "M_{32}, ..., M_{63}"$$
$$r1 = "M_{64}, ..., M_{95}"$$
$$r0 = "M_{96}, ..., M_{127}"$$

When processing a last block of a message, we compose a padding $pad$ as follows:

$$j = 128 - byte\_len(last\_block) - 17$$
$$s = to\_string(bit\_len(M))$$
$$pad = "x80" || "x00"^{j+14} || s$$

In case of message $M$, $pad = "x08" || "x00"^{43} || "x06, x90$

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
| $q = 0$ | $x04\|\|x00^{16}\|\|x80$|
| $q = 1$ | $M\|\|x84$ |
| $q = 2$ | $M\|\|x04\|\|x80$ |
| $q > 2$ | $M\|\|x04\|\|x00^{q-2}\|\|x80$ |

After initialization of TMAC core (shares are loaded and initialization string is processed), the message is then processed in two rounds of TMAC calculation. The first block is composed as:

First block:
$$r = "x00^{14}, M_0, ..., M_{17}"$$

Last block:
$$r = "x00^{14}, M_{18}, ..., M_{33}, x04, x80"$$
