# MPW1 Tests

This markdown describes SPECT API for MPW1 tests and side chanel analysis. The source files are located in [`src/mpw1/`](doc/mpw1/) directory. This firmware is ISAv1 only and includes includes 7 commands for side chanel analysis.

## Table of contents
1. [Setup](#command_setup)
2. [Commands](#commands)
    1. [ECDSA Signature](#ecdsa_sign)
    2. [P-256 Curve Scalar Multiplication (non-masked)](#p256_nonmasked)
    3. [P-256 Curve Scalar Multiplication (masked)](#p256_masked)
    4. [Ed25519 Curve Scalar Multiplication (non-masked)](#ed25519_nonmasked)
    5. [Ed25519 Curve Scalar Multiplication (masked)](#ed25519_masked)
    6. [X25519 (non-masked)](#x25519_nonmasked)
    7. [X25519 (masked)](#x25519_masked)
3. [Side Chanel Countermeasures] (#scc)

## Setup <a name="command_setup"></a>

Before executing any command, user must setup **CMD_ID** and preload constants needed for the ECC algorithms (e.g. curve parameters, primes, ...).

**CMD_ID** is identifier of every command. SPECT FW runs desired command based on this value. The value of **CMD_ID** every for every command is stated in [Commands](#commands) description. User must write the **CMD_ID** on address 0x0000 in SPECTs address space.

Constants for MPW1 FW are specified in [`data/data_ram_in_const_config.yml`](data/data_ram_in_const_config.yml). To generate hex file from this config file, run

```
make data_ram_in_const
```

It generates the hex file to [`data/constants_data_in.hex`](data/constants_data_in.hex) and also address descriptors that are then used in FW source code. After every reset/power-up, user writes the contents of the hex file starting from address 0x0200 in SPECTs address space (can be changed in the mentioned config file).

## Commands <a name="commands"></a>

### ECDSA Signature <a name="ecdsa_sign"></a>

#### CMD_ID: 0xA1

#### Description:

This command performs an ECDSA signature using NIST P-256. It takes ECDSA private key, nonce and 32 byte message digest and generates 64 bytes signature (r, s). In addition, user preloads 32 byte masks for several side chanel countermeasures.

#### Input Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **CMD_ID**    | 0x0000    | 1B    | Command ID |
| **d**         | 0x0020    | 32B   | ECDSA P-256 private key |
| **z**         | 0x0040    | 32B   | Message digest |
| **k**         | 0x0060    | 32B   | ECDSA Nonce |
| **t1**        | 0x0080    | 32B   | Mask for projective coordinates randomization |
| **t2**        | 0x00A0    | 32B   | Mask for scalar randomization |
| **t3**        | 0x00C0    | 32B   | Mask for computation of s signature part |

#### Outputs Table:

| Name          | Address   | Size  | Description |
| - | - | - | - |
| **RET_CODE**  | 0x1000    | 1B    | Return code |
| **Signature** | 0x1020    | 64B   | Signature (r, s) |

#### Return Codes Table:

| Value | Description |
| - | - |
| 0x01  | Signature Success |
| 0x0F  | Signature Fail |

Signature can fail if:

- **k** = 0 (mod q)
- **t1** = 0 (mod p)
- signature part 'r' = 0
- signature part 's' = 0

### P-256 Curve Scalar Multiplication (non-masked) <a name="p256_nonmasked"></a>

### P-256 Curve Scalar Multiplication (masked) <a name="p256_masked"></a>

### Ed25519 Curve Scalar Multiplication (non-masked) <a name="ed25519_nonmasked"></a>

### Ed25519 Curve Scalar Multiplication (masked) <a name="ed25519_masked"></a>

### X25519 (non-masked) <a name="x25519_nonmasked"></a>

### X25519 (masked) <a name="x25519_masked"></a>

## Side Channel Countermeasures <a name="scc"></a>
