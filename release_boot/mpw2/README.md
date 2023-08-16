# SPECT Boot Firmware for MPW2, ISA v0.2, No parity

`start_address = 0x8000`

## SPECT Ops

- `eddsa_verify`
- `sha512_init`
- `sha512_update`
- `sha512_final`

## Expects

- Content of SPECTs Constants ROM = `constants.hex`
