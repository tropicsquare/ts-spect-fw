# ECC Keys Layout in Key Memory

User slot = x

Physical private key slot = 2x

Physical public key slo = 2x + 1

## Metadata

Both slots contain metadata for the slot. The following information is included:

| offset | name | description |
| - | - | - |
| 0x0 | *Curve* | P-256 (0x01) / Ed25519 (0x02) |
| 0x1 | *Origin* | Generate (0x01) / Store (0x02) |
| 0x2 | *Slot Type* | Public (0xAA) / Private (0x55) |
| 0x3 | *Slot Number* | User slot (x) |
| 0x4 | *Padding* | Padding to 256 bits with 0s |

## Private Key Slot

There are two private keys:
1. **d**(ECDSA) and **s**(EdDSA): scalar used to generate public key and used to calculate **S**
part of the signature.
2. **w**(ECDSA) and **prefix**(EdDSA): value derived from **d**/**s**, used for deterministic
nonce derivation.

Both keys are masked when stored to Flash for the first time.

**Splitting of the scalar**

- **d1** = rng \% q256, **d2** = **d** - **d1** \% q256
- **s1** = rng \% q25519, **s2** = **s** - **s1** \% q25519

**Masking of the second part**

- **mask** = rng, **w_masked** = **w** $\oplus$ **mask**
- **mask** = rng, **prefix_masked** = **prefix** $\oplus$ **mask**

| offset | ECDSA | EdDSA |
| - | - | - |
| 0x00 | **d1** | **s1** |
| 0x20 | **w_masked** | **prefix_masked** |
| 0x40 | **d2** | **s2** |
| 0x60 | **mask** | **mask** |
| 0x80 | **metadata** | **metadata** |

## Public Key Slot

| offset | ECDSA | EdDSA |
| - | - | - |
| 0x80 | **metadata** | **metadata** |
| 0xA0 | **A** (64B) | **A** (32B) |

