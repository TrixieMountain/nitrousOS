---
title: "Getting Started"
description: "Get up and running with nitrousOS in minutes"
weight: 1
---

## Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [just](https://github.com/casey/just) command runner (optional, installed via nix-shell)
- Git for cloning the repository

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/TrixieMountain/nitrousOS.git
cd nitrousOS
```

### 2. Test in a VM

The fastest way to try nitrousOS is in a sandboxed QEMU virtual machine:

```bash
# Full desktop environment
just sandbox dinitrogen

# Minimal server
just sandbox oxide

# Headscale coordination server
just sandbox trixie
```

This builds a VM image and launches QEMU with graphical output. No changes are made to your system.

### 3. Explore Available Targets

```bash
just targets
```

Output:
```
Available targets:

  VM Targets (generic):
    dinitrogen-vm    Full-featured desktop
    oxide-vm         Server base (SSH + Tailscale)
    trixie-vm        Headscale coordination server AIO

  OEM Hardware Targets:
    justin-p14s      Lenovo P14s with NVIDIA (dinitrogen)

  Aliases (point to VM targets):
    dinitrogen       -> dinitrogen-vm
    oxide            -> oxide-vm
    trixie           -> trixie-vm
```

## Next Steps

- [Installation Guide](/docs/installation/) - Install on physical hardware with LUKS encryption
- [Configuration](/docs/configuration/) - Customize your system
- [VM Builder](/docs/vm-builder/) - Build images for cloud deployment

## Useful Commands

```bash
# Validate flake syntax
just check

# Update all flake inputs
just update

# Build ISO image
just iso dinitrogen

# Build all VM formats
just build-vms oxide
```

## Getting Help

- [GitHub Issues](https://github.com/TrixieMountain/nitrousOS/issues) - Report bugs and request features
- [GitHub Discussions](https://github.com/TrixieMountain/nitrousOS/discussions) - Ask questions and share ideas
