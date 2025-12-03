---
title: "Installation"
description: "Install nitrousOS on physical hardware with full-disk encryption"
weight: 2
---

## Overview

nitrousOS provides an automated installation script that sets up a fully encrypted system using LUKS2. The installer creates four partitions:

| Partition | Label | Purpose | Encryption |
|-----------|-------|---------|------------|
| 1 | NITROUSBOOT | EFI System Partition | No |
| 2 | NITROUSROOT | Root filesystem | LUKS2 |
| 3 | NITROUSHOME | Home directory | LUKS2 |
| 4 | NITROUSSWAP | Swap space | LUKS2 |

## Requirements

- NixOS live USB or existing NixOS installation
- Target disk (all data will be erased)
- Internet connection for package downloads

## Automated Installation

### Step 1: Boot into NixOS Live Environment

Download the NixOS minimal ISO and boot from it.

### Step 2: Clone nitrousOS

```bash
sudo nix-shell -p git --run "git clone https://github.com/TrixieMountain/nitrousOS.git"
cd nitrousOS
```

### Step 3: Identify Your Target Disk

```bash
lsblk
```

Example output:
```
NAME        SIZE TYPE
nvme0n1     512G disk
sda          32G disk  ← USB drive
```

### Step 4: Run the Installer

```bash
just install /dev/nvme0n1 dinitrogen
```

Replace `/dev/nvme0n1` with your target disk and `dinitrogen` with your desired target.

The installer will:
1. Prompt for LUKS encryption password
2. Create and encrypt partitions
3. Format filesystems
4. Mount everything
5. Install nitrousOS
6. Configure bootloader

### Step 5: Reboot

```bash
sudo reboot
```

Enter your LUKS password at boot to unlock the system.

## Manual Installation

For custom partition layouts, follow these steps:

### Create Partitions

```bash
# Create GPT partition table
parted /dev/nvme0n1 mklabel gpt

# Create EFI partition (512MB)
parted /dev/nvme0n1 mkpart ESP fat32 1MiB 513MiB
parted /dev/nvme0n1 set 1 esp on

# Create root partition
parted /dev/nvme0n1 mkpart primary 513MiB 100%
```

### Setup LUKS Encryption

```bash
# Encrypt root partition
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot

# Format
mkfs.fat -F 32 -n NITROUSBOOT /dev/nvme0n1p1
mkfs.ext4 -L NITROUSROOT /dev/mapper/cryptroot
```

### Mount Filesystems

```bash
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

### Generate Hardware Configuration

```bash
nixos-generate-config --root /mnt
```

### Install nitrousOS

```bash
# Copy nitrousOS to /mnt
cp -r nitrousOS /mnt/etc/nixos/

# Edit flake.nix to add your hardware configuration
# Then install
nixos-install --flake /mnt/etc/nixos/nitrousOS#your-target
```

## Post-Installation

### First Login

For **dinitrogen** (desktop):
- Auto-login is enabled for the default user
- Change your password: `passwd`

For **oxide/trixie** (server):
- Login as `admin` via SSH
- Add your SSH key to `oem/user/admin.nix`

### Update the System

```bash
cd /etc/nixos/nitrousOS
sudo just switch dinitrogen
```

## Troubleshooting

### LUKS Password Not Accepted

Ensure you're using the correct keyboard layout. The installer uses US layout by default.

### Boot Fails

1. Boot from NixOS live USB
2. Unlock LUKS: `cryptsetup open /dev/nvme0n1p2 cryptroot`
3. Mount: `mount /dev/mapper/cryptroot /mnt`
4. Chroot: `nixos-enter --root /mnt`
5. Rebuild: `nixos-rebuild switch --flake /etc/nixos/nitrousOS#target`
