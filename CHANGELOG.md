# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.1.0]

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
