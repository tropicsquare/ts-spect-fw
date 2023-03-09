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

## x25519

| command               | input                 | output        | description |
| - | - | - | - |
| x25519_kpayr_gen_epmh |                       | Etpub, Etpriv | Generates ephemeral key pair for Secure Handshake |
| x25519_cal            | priv, pub, kslot      | R             | Calculates R = priv . pub on Curve25519 |

## ECDSA

| command               | input                 | output        | description |
| - | - | - | - |
| ecdsa_atskey_gen      | kslot                 | d, w, A       | Generates atest key-trio for ECDSA and stores it to kslot |
| ecdsa_atskey_store    | k, kslot              | d, w, A       | Generates atest key-trio for ECDSA based on k and stores it to kslot |
| eddsa_stskey_read     | kslot                 | A             | Reads atest key for ECDSA from kslot |

| command               | input                 | output        | description |
| - | - | - | - |
| ecdsa_sign            | SCh, SCn, z, kslot    | r, s          | Calculates ECDSA signature |

## EdDSA

| command               | input                 | output        | description |
| - | - | - | - |
| eddsa_atskey_gen      | kslot                 | s, prefix, A  | Generates atest key-trio for EdDSA and stores it to kslot |
| eddsa_atskey_store    | k, kslot              | s, prefix, A  | Generates atest key-trio for EdDSA based on k and stores it to kslot |
| eddsa_stskey_read     | kslot                 | A             | Reads atest key for EdDSA from kslot |

| command               | input                 | output        | description |
| - | - | - | - |
| eddsa_set_context     | kslot, SCh, SCn       |               | Sets kontext for EdDSA -- keys and secure channel context |
| eddsa_nonce_prep      | msg_chunk_size        |               | Do first part of calculating nonce r |
| eddsa_nonce_update    | msg_chunk_size        |               | Updates the nonce calculation |
| eddsa_nonce_finish    | msg_chunk_size        |               | Finishes the nonce calculation |
| eddsa_Rpart           |                       |               | Calculates R = r.G |
| eddsa_e_prep          | msg_chunk_size        |               | Do first part of calculating nonce r |
| eddsa_e_update        | msg_chunk_size        |               | Updates the nonce calculation |
| eddsa_e_finish        | msg_chunk_size        |               | Finishes the nonce calculation |
| eddsa_finish          |                       | (R, S)        | Finishes the signature |
