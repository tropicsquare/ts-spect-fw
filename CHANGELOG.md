# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- ECC_Key_Erase now flushes KBUS with the correct slot when error occurs.

### Added

- Public keys are check for validity upon read.

## [v1.2.1] 2026-04-14

### Fixed

- Uninitialized `r4` was used in `point_check_infinity_ed25519` routine.

## [v1.2.0] 2026-04-14

### Changed

- Ed25519 and X25519 uses `get_secure_random` routine in case of GRV provides less then 256 bit of entropy.

## [v1.1.0] 2024-04-14

### Changed

- TMAC mask requires only one GRV call and is extended using SHA-512
- Generic addition on Curve25519 uses Montgomery group law instead of W-25519 birational map
- ECDSA and EdDSA final signature verification use masked double scalar multiplication instead of non-masked montgomery ladder.

### Added

- Op links
- Call checks
- Reset of TMAC state after use
- Better checks for invalid public point for X25519

## [v1.0.0] 2025-07-15

*First stable version*

> [!IMPORTANT]
> This is the first stable version. The development before this version is not logged in this changelog. Do not use versions prior to v1.0.0!
