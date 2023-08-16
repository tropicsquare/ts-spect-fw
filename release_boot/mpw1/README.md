# SPECT Boot Firmware for MPW1, ISA v0.1

`start_address = 0x8000`

## SPECT Ops

- `eddsa_verify`
- `sha512_init`
- `sha512_update`
- `sha512_final`

## Expects

- Content of SPECTs Data RAM In from address `0x0200` up = `constants.hex`
