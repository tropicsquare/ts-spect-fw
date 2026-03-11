# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- TMAC mask requires only one GRV call and is extended using SHA-512
- Ed25519 and X25519 uses `get_secure_random` routine in case of GRV provides less then 256 bit of entropy

### Added

- Op links
- Call checks
- Reset of TMAC state after use

## [v1.0.0] 2025-07-15

*First stable version*

> [!IMPORTANT]
> This is the first stable version. The development before this version is not logged in this changelog. Do not use versions prior to v1.0.0!
