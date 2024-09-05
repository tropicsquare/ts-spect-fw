# Hashing 32-byte strings to GF(p) in SPECT Firmware

This is a description of SPECT FW approach to hashing 32-byte strings (m) to element of GF(p).
Spect uses `hash_to_field` function.

## Domain Separation Tags (DSTs)

Rationale: https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-16.html#name-domain-separation-requireme

Application that instantiates multiple and independent `hash_to_field` instances
MUST enforce domain separation between these instances. In case of SPECT FW, 4 domains are separated:
- ECDSA
- EdDSA
- X25519
- ECC Key (generate/store)

### Requirements:
- Tags MUST be supplied as the DST parameter to `hash_to_field`.
- Tags MUST have nonzero length. A minimum length of 16 bytes is RECOMMENDED to reduce the chance of collisions with other applications.
- Tags SHOULD begin with a fixed identification string that is unique to the application.
- Tags SHOULD include a version number.
- For applications that define multiple ciphersuites, each ciphersuite's tag MUST be different. For this purpose, it is RECOMMENDED to include a ciphersuite identifier in each tag.

SPECT FW uses 30-byte DST. The fixed prefix is `"TS_SPECT_DST"` followed by version and `"\x00"` bytes. The last
byte separates the 4 SPECT FW domains.
| Domain | Separator byte |
| - | - |
| ECDSA | `"\xF1"` |
| EdDSA | `"\xF2"` |
| X25519 | `"\xF3"` |
| ECC Key | `"\xF4"` |

Example of DST for ECDSA in version 1:
```
"TS_SPECT_DST\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xF1"
```

## Expand Message Tag (EXP_TAG)

Expand Message Tag is 32-byte string used to separate use of random point generation in different projects and versions of the projects (e.g. TROPIC01, TROPIC02 ...)

The value of EXP_TAG is `"\x80"` followed by 28 `"\x00"` ended with `"TS"` and byte with the current version.
For TROPIC01 is the EXP_TAG:
```
"\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00TS\x01"
```

## Expand Message

The message m is first expanded to 64 uniform bytes. In case SPECT FW, the function `expand_message` is following:

```
parameters:
    32-byte EXP_TAG
input:
    32 byte message m
    30-byte DST
output:
    64 uniform bytes

function expand_message(m, DST):
    m_len = "\x20"
    dst_len = "\x1E"

    uniform_bytes = SHA512(EXP_TAG || m || m_len || DST || dst_len)
    return uniform_bytes
```

## Hash to Field

```
input:
    32-byte message m
    30-byte DST
    32-byte EXP_TAG
    p - order of GF(p)
output:
    u - element of GF(p)

function hash_to_field(m, DST, p):
    uniform_bytes = expand_message(m, DST)
    x = big-endian encoding of uniform_bytes
    u = x mod p
    return u
```

## SPECT FW usecase:

SPECT FW use the hash_to_field function to generate masks in ECC algorithms.

1. SPECT needs to generate random masking value in GF(p).
2. SPECT executes GRV instruction and gets 32-bytes of random data.
3. SPECT interprets the data as string m.
4. SPECT computes mask = hash_to_field(m, DST, p) with
DST reflecting the current domain.
5. SPECT uses the mask.
