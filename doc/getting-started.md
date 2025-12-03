# Getting Started

This guide will help you get nitrousOS running on your machine or in a VM.

## Prerequisites

### Required

- **Nix** with flakes enabled
- **just** command runner

```bash
# Enable flakes in Nix (add to ~/.config/nix/nix.conf)
experimental-features = nix-command flakes

# Install just
nix-env -iA nixpkgs.just
```

### Optional

- `qemu` - For VM testing (`just sandbox`)
- `qemu-img` - For building VM disk images
- `gpg` - For signing disk images

## Clone the Repository

```bash
git clone https://github.com/yourusername/nitrousOS
cd nitrousOS
```

## Choose Your Target

nitrousOS provides three main targets:

| Target | Use Case |
|--------|----------|
| `dinitrogen` | Desktop workstation with COSMIC DE |
| `oxide` | Server/headless with SSH + Tailscale |
| `trixie` | Headscale coordination server |

## Quick Test (VM)

Test any target in a QEMU VM without affecting your system:

```bash
# Test dinitrogen desktop
just sandbox dinitrogen-vm

# Test oxide server
just sandbox oxide-vm

# Test trixie headscale server
just sandbox trixie-vm
```

## Install on Physical Hardware

See [Installation Guide](installation.md) for full instructions.

Quick version:

1. Boot from NixOS installer ISO
2. Run: `just install /dev/nvme0n1 dinitrogen`
3. Reboot

## Build VM Images

Build deployable disk images for cloud/VM platforms:

```bash
# Build all formats for oxide
just build-vms oxide

# Output in dist/vm/oxide/:
#   oxide.raw, oxide.qcow2, oxide.vmdk, oxide.vdi,
#   oxide.vhdx, oxide-azure.vhd, oxide.ova, oxide-ami.tar.gz
```

## Available Commands

Run `just help` for a complete list, or `just --list` for a quick reference.

## Next Steps

- [Targets](targets.md) - Detailed target descriptions
- [Configuration](configuration.md) - Customize your system
- [Installation](installation.md) - Full installation guide
- [VM Builder](vm-builder.md) - Build disk images for deployment
