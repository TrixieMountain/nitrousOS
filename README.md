# nitrousOS

A modular NixOS-based Linux distribution with full-disk encryption, designed for desktops, servers, and network infrastructure.

## Targets

| Target | Description |
|--------|-------------|
| **dinitrogen** | Full-featured desktop (COSMIC, Pantheon, GNOME, or KDE) |
| **oxide** | Minimal server base (SSH + Tailscale) |
| **trixie** | Headscale coordination server (Tailscale + Headscale + DERP) |

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/nitrousOS
cd nitrousOS

# Show available commands
just help

# Test in a VM
just sandbox oxide-vm

# Build disk images
just build-vms trixie
```

## Installation

### Physical Machine (LUKS Encrypted)

Boot from a NixOS installer ISO, then:

```bash
# Install with full-disk encryption
just install /dev/nvme0n1 dinitrogen
```

This creates:
- `NITROUSBOOT` - EFI partition (FAT32)
- `NITROUSROOT` - Root filesystem (LUKS + ext4)
- `NITROUSHOME` - Home directory (LUKS + ext4)
- `NITROUSSWAP` - Encrypted swap (LUKS)

### VM / Cloud Deployment

```bash
# Build disk images (outputs to dist/vm/<target>/)
just build-vms oxide

# Available formats: RAW, QCOW2, VMDK, VDI, VHDX, Azure VHD, OVA, AMI
```

## Project Structure

```
nitrousOS/
├── flake.nix              # Flake entry point
├── justfile               # Build commands
├── lib/
│   ├── core/              # Essential system components
│   ├── plugin/            # Optional features (desktop, GPU, network)
│   ├── system/            # System variant definitions
│   └── install/           # Installation scripts
└── oem/
    ├── profiles/          # System profiles (network, services, desktop)
    ├── user/              # User definitions (credentials, software)
    └── hardware/          # Machine-specific hardware configs
```

## Documentation

See [doc/](doc/) for detailed documentation:

- [Getting Started](doc/getting-started.md)
- [Targets](doc/targets.md)
- [Installation](doc/installation.md)
- [Configuration](doc/configuration.md)
- [VM Builder](doc/vm-builder.md)

## Requirements

- Nix with flakes enabled
- `just` command runner
- For VM builds: `qemu-img`, `python3`
- For signing: `gpg`

## License

See [LICENSE](LICENSE) for details.
