## FIT CTU - ECC test firmware

x25519 rfc : https://www.rfc-editor.org/rfc/rfc7748

## Inputs:

- `0x0000` : coordinate u, 32-byte string
- `0x0020` : scalar k, 32-byte string
- `0x0040` : mask for euclidean scalar blinding, 256-bit unsigned integer
- `0x0060` : mask for z-coordinate randomization, 256-bit unsigned integer

## Outputs:
- `0x1000` : X25519(k, u), 32-byte string

## Constants:
Preload `data_ram_in_const.hex` from address `0x0200`. 