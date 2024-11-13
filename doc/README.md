# SPECT Firmware Documentation

> **_NOTE:_** Current state of the documentation is incomplete and work progress.

- [`spect_fw_api.pdf`](spect_fw_api/pdf/spect_fw_api.pdf) specifies API provided by the firmware
- [`TMAC.md`](TMAC.md) specifies TMAC function and its usage in SPECT.
- [`deterministic_nonce_generation.md`](deterministic_nonce_generation.md) describes how nonces for ECDSA/EdDSA are generated.
- [`ecc_key_layout.md`](#ecc_key_layout.md) describes layout of ECC keys in each flash memory slot of TROPIC01.
- [`message_processing.md`](message_processing.md) describes how a message is processed in SPECT FW using HASH and TMAC* instructions.
- [`str2point.md`](str2point.md) describes algorithms used in SPECT FW to encode an arbitrary string to a point on an elliptic curve.
- [`hash2field.md`](hash2field.md) describes algorithms used in SPECT FW to hash a 32-byte string into an element of given finite field.
- [`mpw1_tests.md`](mpw1_tests.md) describes special commands and flow for SPECT testing and side chanel evaluation on MPW1.
