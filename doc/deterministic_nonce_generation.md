# Deterministic nonce derivation in TROPIC01 using TMAC

This note describes how nonces for ECDSA/EdDSA are generated in SPECT deterministically using
$\text{KECCAK}$ [1] based MAC function (TMAC).

## Symbols

- $q$ - order of the underlying subgroup
- $G$ - generator of the underlying subgroup
- $M$ - message
- $N$ - TMAC customization byte
- $K$ - key as 256-bit integer
- $X$ - TMAC input data as bytes
- $""$ - empty string

## Introduction

The ECDSA and EdDSA signing algorithms involve usage of a secret nonce (session key). This nonce
MUST be unique for each message signed with given private key. The secrecy and uniqueness is
critical for the security of the signing scheme.

One possibility is to generate nonces randomly. In this case, the whole secrecy of the nonce relies
on the secrecy of TRNG. If it fails to generate unique and secret values, the private key can be
compromised. This solution is also hardly auditable.

For this reason, the nonce is generated deterministically from the private key and the message using
hash functions or key derivation functions. Secrecy of this solution relies on the security of the
function used. It is also easily auditable, if the user know their private key.

When key-pair is generated or stored, SPECT derives a second private key from the first and stores
it together. Nonces are then derived from this second private key.

## TMAC

SPECT uses custom $\text{KECCAK}$ based function to derive a secret nonces - $\text{TMAC}$
(Tropic Message Authentication Code). See [tmac_specification](https://tropic-gitlab.corp.sldev.cz/internal/development-environment/ts-crypto-blocks/-/jobs/81415/artifacts/file/public/tmac_specification.pdf) and [`TMAC.md`](TMAC.md)
for more details about TMAC.




## Customization byte

To avoid random conflicts between different usages of $\text{TMAC}$ in SPECT, customization byte $N$
is used to separate them. This way, even when all other inputs (message, keys...) are equal,
the final input of $\text{TMAC}$ is different. This method is sometimes called "domain separation",
and $N$ would be called $DST$ (Domain Separation Tag).

| use-case          | $N$       |
| -                 | -         |
| ECDSA Key Setup   | `0x0A`    |
| ECDSA Sign        | `0x0B`    |
| EdDSA Sign        | `0x0C`    |

## Secure Channel Values

To avoid repeated signing with the same nonce in case the key and message are equal, values from
TROPIC01 secure channel are mixed in.

- Secure Channel Hash ($sch$) - 32-byte hash from secure channel. It is unique for each session, and equal
for each command within the session.
- Secure Channel Nonce ($scn$) - 2-byte nonce from secure channel. It is unique for each command
within a session, no necessarily unique across sessions.

This way, the uniqueness of the nonce holds even for repeated sign commands using the same key and
message, because the combination of secure channel values is unique for each session and each
command within the session.

## Nonces for ECDSA

ECDSA specific symbols:

- $d$ - private key
- $w$ - second (derivate) private key
- $A$ - public key
- $k$ - secret nonce
- $z$ - message digest

$q =$ `0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551`

### Key Setup

Inputs:

- $d$ - ECDSA private key encoded as bytes in big-endian order

Outputs:

- $d_{int} \in [1, q−1]$ - ECDSA private key as 256-bit integer
- $w_{int}$ - second private key as 256-bit integer
- $A$ - ECDSA public key as two 256-big integers (coordinates $x$ and $y$)

Steps:

1. Decode $d$ from big-endian notation to integer $d_{int}$
2. If $d_{int} \notin [1,q-1]$: FAIL
2. Compute $w_{int} = int(\text{TMAC}(d_{int}, "", N))$
3. Compute $A = d.G$
4. Return $d_{int}, w_{int}, A$

### Nonce Generation

Inputs:

- $z$ - 32-byte message digest to sign using ECDSA
- $sch$ - Secure Channel Hash (32 bytes)
- $scn$ - Secure Channel Nonce (2 bytes)
- $w_{int}$ - second ECDSA private key as 256-bit integer

Output:

- $k \in [1,q-1]$ - ECDSA secret nonce as 256-bit integer

Steps:

1. Compute $k1 = int(\text{TMAC}(w_{int}, sch||scn||z, N))$
2. Compute $k2 = int(\text{TMAC}(k1, "", N))$
3. Compute $k = (k1 + k2 \times 2^{256}) \pmod{q}$
4. If $k == 0$: FAIL, else: Return $k$

## Nonces for EdDSA

EdDSA specific symbols:

- $k$ - master private key (sometimes called seed)
- $s$ - first private key (private scalar)
- $prefix$ - second private key
- $A$ - public key
- $r$ - secret nonce
- $M$ - message

$q =$ `0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed`

### Key Setup

Inputs:

- $k$ - 32-byte master private key

Outputs:

- $s$ - first private key as 256-bit integer
- $prefix$ - second private key as 256-bit integer
- $A$ - public key

Steps:

1. Compute $h = \text{SHA512}(k)$
2. Derive $s$ from lower 32 bytes of $h$ as described in [2] section 5.1.5
3. Reduce $s \pmod{q}$
4. Derive $prefix$ from upper 32 bytes of $h$ as integer in little-endian encoding
5. Compute $A = s.G$ and encode it to 32 bytes as described in [2] section 5.1.5
6. Return $s, prefix, A$

### Nonce Generation

Inputs:

- $M$ - message to sign using EdDSA (arbitrary length)
- $sch$ - Secure Channel Hash (32 bytes)
- $scn$ - Secure Channel Nonce (2 bytes)
- $prefix$ - second EdDSA private key as 256-bit integer

Outputs:

- $r \in [0, q-1]$ - EdDSA secret nonce as 256-bit integer

Steps:

1. Compute $r1 = int(\text{TMAC}(prefix, sch||scn||M, N))$
2. Compute $r2 = int(\text{TMAC}(r1, "", N))$
3. Compute $r = (r1 + r2 \times 2^{256}) \pmod{q}$
4. Return $r$

## References

[1] FIPS 202, SHA-3 STANDARD: PERMUTATION-BASED HASH AND EXTENDABLE-OUTPUT FUNCTIONS, August 2015,
[https://doi.org/10.6028/NIST.FIPS.202]

[2] RFC8032, Edwards-Curve Digital Signature Algorithm (EdDSA), January 2017,
[https://datatracker.ietf.org/doc/html/rfc8032#section-5.1.5]