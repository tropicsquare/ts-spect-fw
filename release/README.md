# SPECT Production Firmware for MPW2, ISA v0.2

`start_address = 0x8000`

## SPECT Ops - Application
- `clear`
### ECC Key
- `ecc_key_generate`
- `ecc_key_store`
- `ecc_key_read`
- `ecc_key_erase`

### X25519
- `x25519_kpair_gen`
- `x25519_sc_et_eh`
- `x25519_sc_et_sh`
- `x25519_sc_st_eh`

### EdDSA
- `eddsa_set_context`
- `eddsa_nonce_init`
- `eddsa_nonce_update`
- `eddsa_nonce_finish`
- `eddsa_R_part`
- `eddsa_e_at_once`
- `eddsa_e_prep`
- `eddsa_e_update`
- `eddsa_e_finish`
- `eddsa_finish`

### ECDSA
- `ecdsa_sign`

## SPECT Ops - Debug
- `x25519_dbg`
- `ecdsa_sign_dbg`
- `eddsa_set_context_dbg`
- `eddsa_nonce_init`
- `eddsa_nonce_update`
- `eddsa_nonce_finish`
- `eddsa_R_part`
- `eddsa_e_at_once`
- `eddsa_e_prep`
- `eddsa_e_update`
- `eddsa_e_finish`
- `eddsa_finish`

## Expects

- Content of SPECTs Constants ROM = `constants.hex`
