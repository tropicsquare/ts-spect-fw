# Tropic Message Authentication Code

This note describes $\text{TMAC}$ function. $\text{TMAC}$ is used in SPECT for deterministic
generation of nonces (session keys) for ECDSA and EdDSA.
See [`deterministic_nonce_generation.md`](deterministic_nonce_generation.md)

## TMAC Function Definition

SPECT implements custom $\text{KECCAK}$ based function - $\text{TMAC}$
(Tropic Message Authentication Code). The $\text{TMAC}$ function has following inputs:

- $K$ - key as 256-bit integer
- $X$ - data as bytes
- $N$ - customization bytes

and is defined as follows.
Let $$\text{KECCAK}_{\text{TMAC}} = \text{SPONGE[KECCAK-f[400],} tmacpadrule, \text{144]}(M, 256)$$
then $$\text{TMAC}(K,X,N) = \text{KECCAK}_{\text{TMAC}}(initstr||X||"00")$$
where $$initstr = (N||x20||\text{little-endian}(K)||x00||x00).$$

### TMAC Padding Rule

$\text{TMAC}$ defines padding rule based on $pad10^*1$ padding rule from [1] as follows:

1. Set $zlen$ to size of $X$ in bytes modulo 18
2. If $zlen == 1$: Return ($x84$)
3. If $zlen == 0$: $zlen = 16$
4. Set $zeros$ to $zlen-2$ zero bytes
5. Return ($x04||zeros||x80$)

> NOTE: initialization string is always 36 bytes (2 aligned blocks). Thus only size of X is needed
> to determine the correct padding.

Padding table:

| $zlen$ | $padding$ |
| - | - |
| $0$ | $x04\|\|x00^{16}\|\|x80$|
| $1$ | $x84$ |
| $2$ | $x04\|\|x80$ |
| $>2$ | $x04\|\|x00^{zlen-2}\|\|x80$ |

### TMAC Integer Encoding

The key $K$ as input to $\text{TMAC}$ is always a 256-bit integer. $\text{TMAC}$ it self specifies
the encoding to bytes that are then integrated to the input of underlying $\text{SPONGE}$ function.
The encoding is **big-endian**. The reason is to bind the usage closer to the cryptographic
algorithm, where the key is usually used as integer, and separate it from the encoding specified by
different schemes or protocols.

$\text{TMAC}$ also specifies how to decode its output to integer - $int(\text{TMAC}(K,X,N))$.
The output of $\text{TMAC}$ is always 32 bytes. To decode an integer from these bytes, use
**big-endian** encoding.

The rationale behind choosing big-endian (even if TROPIC01 generally uses little-endian) is to
simplify usage of $\text{TMAC}$ in SPECT, that works with 256-bit registers.

## Implementation and Usage in SPECT

$\text{TMAC}$ uses $\text{KECCAK}$ permutation function with $p = 400$ and $r = 18$. Thus size of
one block of data to be processed is 18 bytes. Output size is 32 bytes. SPECT supports 4
instructions for $\text{TMAC}$:

### TMAC Init (`TMAC_IT`)

Initialize underlying $\text{KECCAK}$ with initialization vectors and masks.

### TMAC Initialization String (`TMAC_IS`)

Takes input key $K$ and customization byte $N$ and updates the underlying $\text{KECCAK}$ with
$initstr$.

### TMAC Update (`TMAC_UP`)

Updates the underlying $\text{KECCAK}$ with one block (18 bytes) of data. It is responsibility
of the programmer to include padding.

### TMAC Read (`TMAC_RD`)

Squeeze 32 bytes from the underlying $\text{KECCAK}$. Due to flaw in $\text{TMAC}$ core design.
The state of the $\text{KECCAK}$ is corrupted after this instruction. To use is again, it MUST be
initialized before.

## References

[1] FIPS 202, SHA-3 STANDARD: PERMUTATION-BASED HASH AND EXTENDABLE-OUTPUT FUNCTIONS, August 2015,
[https://doi.org/10.6028/NIST.FIPS.202]