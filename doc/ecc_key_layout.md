# ECC Keys Layout in Key Memory

User slot = x

Physical private key slot = 2x

Physical public key slo = 2x + 1

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
| 0x08 | **w_masked** | **prefix_masked** |
| 0x10 | **d2** | **s2** |
| 0x18 | **mask** | **mask** |

## Public Key Slot

| offset | ECDSA | EdDSA |
| - | - | - |
| 0x00 | **metadata** | **metadata** |
| 0x08 | **A** (64B) | **A** (32B) |

