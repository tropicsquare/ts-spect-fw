# SPECT API

## Glossary
| | |
| - | - |
| priv              | private key (scalar) for X25519 |
| pub               | public key (point) for X25519 |
| kslot             | key slot |
| k                 | private key for generation of ECDSA and EdDSA key-trios |
| SCh               | Secure Channel Hash |
| CSn               | Secure Channel Nonce |
| z                 | Message digest for ECDSA |
| msg_chunk_size    | Number of bytes of message to be read from CPB during eddsa_nonce_prep/update/finish |

## in/out comunication

By default, SPECT reads input data (message, kslot etc.) and writes output data from/to buffer located in CPB. For debug, it is convenient to have a possibility to use Data RAM In accessible by AHB instate. To achieve that, modify command ID as: NewID = ID + 0x80.

## x25519

| command               | ID    | input                             | output                | description |
| - | - | - | - | - |
| x25519_kpayr_gen_ephm | 0x11  |                                   | $E_{TPub}, E_{TPriv}$ | Generates ephemeral key pair for Secure Handshake |
| x25519_kpay_write     | 0x12  | $S_{HiPub}$, kslot                |                       | Writes X25519 public key to kslot |
| x25519_kpay_read      | 0x13  | kslot                             | $S_{HiPub}$           | Reads X25519 public key from kslot |
| x25519_cal_1          | 0x14  | $E_{TPriv}$, $E_{HPub}$           | R                     | X25519($E_{TPriv}, E_{HPub}$) |
| x25519_cal_2          | 0x15  | $S_{TPriv}$, $E_{HPub}$           | R                     | X25519($S_{TPriv}, E_{HPub}$) |
| x25519_cal_3          | 0x16  | $E_{TPriv}$, $S_{HiPub}$, kslot   | R                     | X25519($E_{TPriv}, S_{HiPub}$) |

## ECDSA

| command               | ID    | input                 | output        | description |
| - | - | - | - | - |
| ecdsa_atskey_gen      | 0x21 | kslot                  | d, w, A       | Generates atest key-trio for ECDSA and stores it to kslot |
| ecdsa_atskey_store    | 0x22 | k, kslot               | d, w, A       | Generates atest key-trio for ECDSA based on k and stores it to kslot |
| eddsa_stskey_read     | 0x23 | kslot                  | A             | Reads atest key for ECDSA from kslot |

| command               | ID    | input                 | output        | description |
| - | - | - | - | - |
| ecdsa_sign            | 0x24  | SCh, SCn, z, kslot    | (r, s)        | Calculates ECDSA signature of z using keys in kslot |

## EdDSA

| command               | ID    | input                | output        | description |
| - | - | - | - | - |
| eddsa_atskey_gen      | 0x31  | kslot                | s, prefix, A  | Generates atest key-trio for EdDSA and stores it to kslot |
| eddsa_atskey_store    | 0x32  | k, kslot             | s, prefix, A  | Generates atest key-trio for EdDSA based on k and stores it to kslot |
| eddsa_stskey_read     | 0x33  | kslot                | A             | Reads atest key for EdDSA from kslot |

| command               | ID    | input                | output        | description |
| - | - | - | - | - |
| eddsa_set_context     | 0x41  | kslot, SCh, SCn      |               | Sets context for EdDSA -- keys and secure channel context |
| eddsa_nonce_init      | 0x42  |                      |               | Do first part of calculating nonce r - TMAC_INIT(prefix, 0x0C) |
| eddsa_nonce_update    | 0x43  |                      |               | Updates the nonce calculation |
| eddsa_nonce_finish    | 0x44  | msg_chunk_size       |               | Finishes the nonce calculation |
| eddsa_Rpart           | 0x45  |                      |               | Calculates R = r.G |
| eddsa_e_prep          | 0x46  | msg_chunk_size       |               | Do first part of calculating nonce r |
| eddsa_e_update        | 0x47  | msg_chunk_size       |               | Updates the nonce calculation |
| eddsa_e_finish        | 0x48  | msg_chunk_size       |               | Finishes the nonce calculation |
| eddsa_finish          | 0x49  |                      | (R, S)        | Finishes the signature |

## Debug commands

| command               | ID    | input                     | output        | description |
| - | - | - | - | - |
| x25519_cal_dbg        | 0x1f  | Priv, Pub                 | R             | X25519(Priv, Pub) |
| ecdsa_sign_dbg        | 0x2f  | SCh, SCn, z, d, w, A      | (r, s)        | Calculates ECDSA signature of z using key-trio d, w, A |
| eddsa_set_context_dbg | 0x3f  | SCh, SCn, s, prefix, A    |               | Sets context for EdDSA -- keys and secure channel context |
| eddsa_sign_dbg        | 0x4f  | SCh, SCn, s, prefix, A, M | (r, s)        | Calculates EdDSA signature of M using key-trio s, prefix, A, size of M is fixed to 32 bytes |
