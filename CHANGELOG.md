# Changelog

All notable changes to nitrousOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2024-12-03

### Added
- **OEM Profiles**: Decoupled system profiles from hardware configuration
  - `oem/profiles/dinitrogen/` - Full-featured desktop with COSMIC DE
  - `oem/profiles/oxide/` - Server base with SSH + Tailscale
  - `oem/profiles/trixie/` - Headscale coordination server AIO
- **LUKS Install Script**: `lib/install/nitrousOS-install.sh` for encrypted physical installs
  - Creates NITROUSBOOT, NITROUSROOT, NITROUSHOME, NITROUSSWAP partitions
  - Full LUKS2 encryption for root, home, and swap
- **VM Targets**: Hardware-agnostic targets for VM/cloud deployment
  - `dinitrogen-vm`, `oxide-vm`, `trixie-vm`
  - Uses QEMU guest profile with simple disk layout
- **OEM Hardware Section**: Separate section in flake for physical machine configs
  - Example: `justin-p14s` for Lenovo P14s with NVIDIA
- **VM Builder**: Comprehensive disk image generation
  - Formats: RAW, QCOW2, VMDK, VDI, VHDX, Azure VHD, OVA, AMI
  - SHA256 checksums and GPG signing
  - Parallel-safe builds with target isolation
- **Justfile Overhaul**: Pretty help output with grouped recipes
  - System, utility, and VM builder command groups
  - `just install` command for physical installations
- **Documentation**: Created `doc/` directory with guides

### Changed
- Renamed `nitrousOS-experimental` references to `nitrousOS`
- Updated trixie description to "Headscale coordination server AIO"
- Flake structure reorganized with VM targets and OEM hardware sections
- All build output now goes to `dist/` with target subdirectories

### Removed
- `configuration.nix` - Configuration now in flake.nix and profiles
- `oem/user/justin.nix` - Moved to `oem/profiles/dinitrogen/`

## [0.2.1] - 2024-11-XX

### Added
- Licensing structure
- Flake.lock

### Changed
- Refactored working config into long-term structure

## [0.2.0] - 2024-11-XX

### Changed
- Deleted nitrousOS system as the whole project is nitrousOS
- Removed old dead code remnants

## [0.1.0] - 2024-XX-XX

### Added
- Initial project structure
- Core NixOS configuration
- Plugin system for optional features
- System variants: dinitrogen, oxide, trixie
