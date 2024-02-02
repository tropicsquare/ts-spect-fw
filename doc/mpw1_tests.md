# MPW1 Tests

This markdown describes SPECT API for MPW1 tests and side chanel analysis. The source files are located in [`src/mpw1/`](../src/mpw1/) directory. This firmware is ISAv1 only and includes 7 commands for side chanel analysis.

---
## Table of Contents

1. [Setup](#command_setup)
2. [Commands](#commands)
    1. [ECDSA Signature](#ecdsa_sign)
    2. [P-256 Curve Scalar Multiplication (non-masked)](#p256_nonmasked)
    3. [P-256 Curve Scalar Multiplication (masked)](#p256_masked)
    4. [Ed25519 Curve Scalar Multiplication (non-masked)](#ed25519_nonmasked)
    5. [Ed25519 Curve Scalar Multiplication (masked)](#ed25519_masked)
    6. [X25519 (non-masked)](#x25519_nonmasked)
    7. [X25519 (masked)](#x25519_masked)
3. [Side Chanel Countermeasures](#scc)
    1. [Scalar Multiplication](#scc_scm)
    2. [ECDSA Signature](#scc_ecdsa_sign)


---
## Setup <a name="command_setup"></a>

### Firmware Compilation and Preload

To compile the MPW1 firmware, run

```
make compile_mpw1
```

This compiles the MPW1 firmware to [`build_mpw1/main_mpw1.hex`](../build_mpw1/main_mpw1.hex) directory. User then writes this hex file to SPECTs Instruction RAM (from address `0x8000` in SPECTs address space).

Ensure you have the `spect_compiler` binaries in the environment path.

---
### Constants

Constants for MPW1 FW are specified in [`data/data_ram_in_const_config.yml`](../data/data_ram_in_const_config.yml).

To generate hex file from this config file, run

```
make data_ram_in_const
```

It generates the hex file to [`data/constants_data_in.hex`](../data/constants_data_in.hex) and also address descriptors that are then used in FW source code. This target is called automatically when running `compile_mpw1` target.

After every reset/power-up, user must write the content of the hex file starting from address `0x0200` in SPECTs address space (the address can be changed in the mentioned config file).

---
### Command ID

**CMD_ID** is identifier of every command. SPECT FW runs desired command based on this value. The value of **CMD_ID** for every command is stated in [Commands](#commands) description.

To select particular command to be executed by the FW, user must write the **CMD_ID** on address `0x0000` in SPECTs address space before launching SPECT with **COMMAND[START]** register.

---
## Commands <a name="commands"></a>

This section provides an overview of commands supported by MPW1 SPECT firmware. All commands perform some elliptic curve operation or whole DSA scheme. All commands use the same algorithm to compute scalar point multiple on a elliptic curve: [Montgomery ladder](https://eprint.iacr.org/2017/293) (conditional swap version). For more information about the ECC algorithms used, refer to headers of source files in [`src/ecc_math`](../src/ecc_math/).

If user specifies different **CMD_ID** then the ones stated below, SPECT FW ends with **RET_CODE** `0xF0`.

### ECDSA Signature <a name="ecdsa_sign"></a>

#### CMD_ID: `0xA1`

#### Description:

This command performs an ECDSA signature using NIST P-256. It takes ECDSA private key, nonce and 32 byte message digest and generates 64 bytes signature (r, s). In addition, user preloads 32 byte masks for several side chanel countermeasures.

#### Input Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **CMD_ID**    | `0x0000`  | 1B    | Command ID |
| **d**         | `0x0020`  | 32B   | ECDSA P-256 private key |
| **z**         | `0x0040`  | 32B   | Message digest |
| **k**         | `0x0060`  | 32B   | ECDSA Nonce |
| **t1**        | `0x0080`  | 32B   | Mask for projective coordinates randomization |
| **t2**        | `0x00A0`  | 32B   | Mask for scalar randomization |
| **t3**        | `0x00C0`  | 32B   | Mask for computation of s signature part |

#### Outputs Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **RET_CODE**  | `0x1000`  | 1B    | Return code |
| **Signature** | `0x1020`  | 64B   | Signature (r, s) |

#### Return Codes Table:

| Value     | Description |
| - | -     |
| `0x01`    | Signature Success |
| `0x0F`    | Signature Fail |

Signature can fail if:

- **k** = 0 (mod q)
- **t1** = 0 (mod p)
- signature part 'r' = 0
- signature part 's' = 0

---
### P-256 Curve Scalar Multiplication (non-masked) <a name="p256_nonmasked"></a>

#### CMD_ID: `0xB1`

#### Description:

This command computes scalar multiple **Q = kP** of a point **P** on a NIST P-256 elliptic curve. This version does not include any side chanel countermeasures. 

#### Input Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **CMD_ID**    | `0x0000`    | 1B    | Command ID |
| **k**         | `0x0020`    | 32B   | Scalar |
| **Px**        | `0x0040`    | 32B   | Point x-coordinate |
| **Py**        | `0x0060`    | 32B   | Point y-coordinate |

#### Outputs Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **RET_CODE**  | `0x1000`    | 1B    | Return code |
| **Qx**        | `0x1020`    | 32B   | Result x-coordinate |
| **Qy**        | `0x1020`    | 32B   | Result y-coordinate |

---
### P-256 Curve Scalar Multiplication (masked) <a name="p256_masked"></a>

#### CMD_ID: `0xB2`

#### Description:

This command computes scalar multiple **Q = kP** of a point **P** on a NIST P-256 elliptic curve. This version includes 2 side-chanel countermeasures: scalar and projective coordinates randomization. Refer to [Scalar Multiplication](#scc_scm).
    
#### Input Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **CMD_ID**    | `0x0000`    | 1B    | Command ID |
| **k**         | `0x0020`    | 32B   | Scalar |
| **Px**        | `0x0040`    | 32B   | Point x-coordinate |
| **Py**        | `0x0060`    | 32B   | Point y-coordinate |
| **t1**        | `0x0080`    | 32B   | Mask for projective coordinates randomization |
| **t2**        | `0x00A0`    | 32B   | Mask for scalar randomization |

#### Outputs Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **RET_CODE**  | `0x1000`    | 1B    | Return code |
| **Qx**        | `0x1020`    | 32B   | Result x-coordinate |
| **Qy**        | `0x1020`    | 32B   | Result y-coordinate |

---
### Ed25519 Curve Scalar Multiplication (non-masked) <a name="ed25519_nonmasked"></a>

#### CMD_ID: `0xC1`

This command computes scalar multiple **Q = kP** of a point **P** on an Ed25519 elliptic curve. This version does not include any side chanel countermeasures.

#### Input Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **CMD_ID**    | `0x0000`  | 1B    | Command ID |
| **k**         | `0x0020`  | 32B   | Scalar |
| **Px**        | `0x0040`  | 32B   | Point x-coordinate |
| **Py**        | `0x0060`  | 32B   | Point y-coordinate |

#### Outputs Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **RET_CODE**  | `0x1000`  | 1B    | Return code |
| **Qx**        | `0x1020`  | 32B   | Result x-coordinate |
| **Qy**        | `0x1020`  | 32B   | Result y-coordinate |

---
### Ed25519 Curve Scalar Multiplication (masked) <a name="ed25519_masked"></a>

#### CMD_ID: `0xC2`

#### Description:

This command computes scalar multiple **Q = kP** of a point **P** on a Ed25519 elliptic curve. This version includes 2 side-chanel countermeasures: scalar and projective coordinates randomization. Refer to [Scalar Multiplication](#scc_scm).
    
#### Input Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **CMD_ID**    | `0x0000`  | 1B    | Command ID |
| **k**         | `0x0020`  | 32B   | Scalar |
| **Px**        | `0x0040`  | 32B   | Point x-coordinate |
| **Py**        | `0x0060`  | 32B   | Point y-coordinate |
| **t1**        | `0x0080`  | 32B   | Mask for projective coordinates randomization |
| **t2**        | `0x00A0`  | 32B   | Mask for scalar randomization |

#### Outputs Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **RET_CODE**  | `0x1000`  | 1B    | Return code |
| **Qx**        | `0x1020`  | 32B   | Result x-coordinate |
| **Qy**        | `0x1020`  | 32B   | Result y-coordinate |

---
### X25519 (non-masked) <a name="x25519_nonmasked"></a>

#### CMD_ID: `0xD1`

#### Description:

This command computes X25519(k, u) function as defined in [`RFC7748`](https://datatracker.ietf.org/doc/html/rfc7748). This version does not include any side chanel countermeasures.
    
#### Input Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **CMD_ID**    | `0x0000`  | 1B    | Command ID |
| **k**         | `0x0020`  | 32B   | Scalar |
| **u**         | `0x0040`  | 32B   | Point u-coordinate |
| **t1**        | `0x0080`  | 32B   | Mask for projective coordinates randomization |
| **t2**        | `0x00A0`  | 32B   | Mask for scalar randomization |

#### Outputs Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **RET_CODE**  | `0x1000`  | 1B    | Return code |
| **x**         | `0x1020`  | 32B   | Result x-coordinate |

---

### X25519 (masked) <a name="x25519_masked"></a>

#### CMD_ID: `0xD2`

#### Description:

This command computes X25519(k, u) function as defined in [`RFC7748`](https://datatracker.ietf.org/doc/html/rfc7748). This version includes 2 side-chanel countermeasures: scalar and projective coordinates randomization. Refer to [Scalar Multiplication](#scc_scm).
    
#### Input Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **CMD_ID**    | `0x0000`  | 1B    | Command ID |
| **k**         | `0x0020`  | 32B   | Scalar |
| **u**         | `0x0040`  | 32B   | Point u-coordinate |
| **t1**        | `0x0080`  | 32B   | Mask for projective coordinates randomization |
| **t2**        | `0x00A0`  | 32B   | Mask for scalar randomization |

#### Outputs Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **RET_CODE**  | `0x1000`  | 1B    | Return code |
| **x**         | `0x1020`  | 32B   | Result x-coordinate |

---
## Side Channel Countermeasures <a name="scc"></a>

This section provides an overview on how MPW1 SPECT firmware implements some side chanel countermeasures on elliptic curves. All ECC algorithms are performed in constant time (number of clock cycles). The only case when the command is not performed in constant time is when it fails.

### Scalar Multiplication <a name="scc_scm"></a>

MPW1 SPECT firmware implements 2 side chanel countermeasures on ECC scalar point multiplication:

#### 1. Projective coordinates randomization:

SPECT FW uses projective coordinates:

$$(x, y) = (X, Y, Z)$$

where

$$x = X/Z, y = Y/Z$$

to perform ECC point addition/doubling. The projective coordinates are ambiguous: $(X, Y, Z) = (\lambda X, \lambda Y, \lambda Z)$. Therefore for each computation, the absolute values can differ. SPECT FW, before every computation, transform affine coordinates to projective as follows:

$$(x, y) \rightarrow (t1 x, t1 y, t1)$$

#### 2. Scalar randomization:

SPECT includes and special instruction to randomize the scalar. This instruction transforms the 256 bit scalar **k** to its 512 bit equivalent using following function:

$$Blind(k, t2, q) := q \times (t2 | (2^{255} + 2^{223})) + k$$

---

### ECDSA Signature <a name="scc_ecdsa_sign"></a>

When computing ECDSA s-part, multiplicative inversion of the nonce **k** is computed. SPECT FW masks this operation by multiplying the nonce with a random number first. The resulting equation for s-part is following:

$$s = (z\cdot t3 + r \cdot t3 \cdot d) \cdot (k \cdot t3)^{-1}$$

In addition, the $r \cdot t3 \cdot d$ is computed in such order, so we avoid computing $r \cdot d$.

---
