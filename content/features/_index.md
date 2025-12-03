---
title: "Features"
description: "Explore nitrousOS capabilities"
---

## Security First

### Full-Disk Encryption

nitrousOS supports LUKS2 encryption for root, home, and swap partitions. The automated installer handles all the complexity.

```bash
just install /dev/nvme0n1 dinitrogen
```

Four encrypted partitions are created automatically:
- **NITROUSBOOT** - EFI system partition (unencrypted)
- **NITROUSROOT** - Root filesystem (LUKS2)
- **NITROUSHOME** - Home directory (LUKS2)
- **NITROUSSWAP** - Swap space (LUKS2)

### SSH Hardening

Server variants (Oxide, Trixie) are hardened by default:
- Key-based authentication only
- Root login disabled
- Password authentication disabled

---

## Modular Plugin System

Enable only what you need. nitrousOS uses a plugin architecture where features are opt-in.

### Desktop Environments

Choose from four desktop environments:

| DE | Description | Best For |
|----|-------------|----------|
| **COSMIC** | Modern, System76's new DE | Performance, aesthetics |
| **GNOME** | Feature-rich, polished | Familiarity, integration |
| **KDE Plasma 6** | Highly customizable | Power users |
| **Pantheon** | Lightweight, elegant | simplicity |

```nix
# Pick one
nitrousOS.plugin.desktop.cosmic.enable = true;
```

### Software Categories

```nix
nitrousOS.software.core.enable = true;        # vim, git, wget
nitrousOS.software.browsers.enable = true;    # Firefox, Chromium
nitrousOS.software.security.enable = true;    # KeePassXC, Tailscale
nitrousOS.software.communication.enable = true; # Signal, Thunderbird
nitrousOS.software.dev.enable = true;         # Dev tools
```

---

## Dynamic GPU Control

Perfect for laptops with hybrid NVIDIA/Intel graphics.

```nix
nitrousOS.plugin.dynamicGpu = {
  enable = true;
  defaultMode = "igpu-only";
};
```

### Three Modes

| Mode | Description | Power Usage |
|------|-------------|-------------|
| `auto` | Automatic switching | Medium |
| `igpu-only` | Integrated only | Low |
| `dgpu-forced` | Discrete always on | High |

### CLI Commands

```bash
# Check current mode
gpu-mode

# Switch modes
gpu-mode auto
gpu-mode igpu
gpu-mode dgpu

# Run app on discrete GPU
nvidia-offload blender
```

---

## Multi-Platform Deployment

Build once, deploy anywhere. Eight output formats supported:

### Formats

- **RAW** - Direct disk image
- **QCOW2** - QEMU/KVM, Proxmox
- **VMDK** - VMware
- **VDI** - VirtualBox
- **VHDX** - Hyper-V
- **Azure VHD** - Microsoft Azure (fixed, aligned)
- **OVA** - VMware/VirtualBox import
- **AMI** - AWS EC2

### Build Command

```bash
just build-vms oxide
```

---

## Reproducible Builds

nitrousOS uses Nix Flakes for 100% reproducible builds.

### Benefits

- **Consistent** - Same inputs = same outputs
- **Auditable** - Every dependency is tracked
- **Rollback** - Easy to revert changes
- **Shareable** - Anyone can reproduce your exact system

### Lock File

```bash
# Update all inputs
just update

# Check for issues
just check
```

---

## Three System Variants

One repository, three optimized configurations:

### Dinitrogen

Full-featured desktop for daily use.

- COSMIC desktop
- All software categories
- Dynamic GPU support
- Auto-login

### Oxide

Minimal server foundation.

- SSH only
- Tailscale mesh networking
- Perfect for Docker/Kubernetes
- Extend with your services

### Trixie

Self-hosted network infrastructure.

- Headscale control server
- Built-in DERP relay
- ACME certificates
- Multiple operation modes

---

## User Profile System

Users are defined separately from system configuration and conditionally activated.

```nix
# oem/user/myuser.nix
let
  enableForSystems = [ "dinitrogen" ];
  enabled = builtins.elem (config.nitrousOS.system or "") enableForSystems;
in
{
  config = lib.mkIf enabled {
    users.users.myuser = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
}
```

This user only exists on `dinitrogen` systems.
