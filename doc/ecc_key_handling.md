# ECC Keys Layout in Key Memory

SPECT FW is using 2 physical slots to store ECC keys. This is to avoid handling of private part when it is not needed. Let user slot be $X$, then

Private key slot = $2X$

Public key slot = $2X+1$

## Metadata

Both slots contain **metadata** for the slot. The following information is included:

| Offset | Name | Description |
| - | - | - |
| 0x0 | *Curve* | P-256 (0x01) / Ed25519 (0x02) |
| 0x1 | *Origin* | Generate (0x01) / Store (0x02) |
| 0x2 | *Slot Type* | Public (0xAA) / Private (0x55) |
| 0x3 | *Slot Number* | User slot ($X$) |
| 0x4 | *Padding* | Padding to 256 bits with 0s |

When SPECT FW is processing _**ECC_Key_Read**_ TROPIC01 L3 Command, it first reads the **metadata**
from Public slot and checks it in 4 separate steps:

1. Check _Origin_ == 'Generate' or 'Store', else fail immediately.
2. Check _Slot type_ == 'Public', else fail immediately.
3. Check _Slot number_ == X, else fail immediately.
4. Check _Curve_ == 'Ed25519' or 'P-256', else fail immediately.

When

## Private Key Slot

There are two private keys:
1. **d** (ECDSA) / **s** (EdDSA) : Scalar used to generate public key **A** and to calculate **S** part of a signature.
2. **w** (ECDSA) / **prefix** (EdDSA) : Value derived from the first private key, used for deterministic nonce derivation.

Both keys are masked when stored to ECC slot for the first time. The mask is a 256-bit random number **r** fetched from TROPIC01s internal TRNG. When a random element of a finite field $GF(p)$ shall be generated, [`hash2field`](hash2field.md) method is used to ensure pseudo-random distribution of the probabilities for
each element to be generated form integer in $[0, 2^{256}-1]$

### Splitting of the scalar

Scalar is randomized using additive splitting method as described in [1]. The following operations are always in $GF(\#E)$ finite field, where $\#E$ is the order of the underlying group (curve order).

- **d1** = **r**, **d2** = **d** - **d1**
- **s1** = **r**, **s2** = **s** - **s1**

When ever the scalar is used for DSA, it is re-randomized with new **r'** as:

- **d1'** = **d1** - **r'**, **d2'** = **d2** + **r'**
- **s1'** = **s1** - **r'**, **s2'** = **s2** + **r'**

### Masking of the second part

The second private key is masked simply by splitting it into 2 shares using bitwise XOR operation.

- **mask** = **r**, **w_masked** = **w** $\oplus$ **mask**
- **mask** = **r**, **prefix_masked** = **prefix** $\oplus$ **mask**

Whenever the second part is used for DSA, it is un-masked as:

- **w** = **mask** $\oplus$ **w_masked**
- **prefix** = **mask** $\oplus$ **prefix_masked**

It is necessary to use the raw value of **w**, or **prefix** for the deterministic nonce generation during DSA.

### Private slot layout

| Offset | ECDSA | EdDSA |
| - | - | - |
| 0x00 | **d1** | **s1** |
| 0x20 | **w_masked** | **prefix_masked** |
| 0x40 | **d2** | **s2** |
| 0x60 | **mask** | **mask** |
| 0x80 | **metadata** | **metadata** |

## Public Key Slot

Public key **A** is computed when the private part is being generated in, or stored to TROPIC01, and is never recomputed again.

### Public slot layout

| Offset | ECDSA | EdDSA |
| - | - | - |
| 0x80 | **metadata** | **metadata** |
| 0xA0 | **A** (64B) | **A** (32B) |

## References

- [1] C. Clavier and M. Joye, Universal Exponentiation Algorithm. Proceedings of CHES’01, LNCS vol. 2162, SpringerVerlag, 2001, pp. 300-308. https://marcjoye.github.io/papers/CJ01univ.pdf