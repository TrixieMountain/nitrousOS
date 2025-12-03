# Installation Guide

This guide covers installing nitrousOS on physical hardware with full-disk encryption.

For VM/cloud deployment, see [VM Builder](vm-builder.md).

## Prerequisites

- NixOS installer ISO (live USB)
- Target disk (NVMe or SSD recommended)
- At least 32GB disk space
- Nix with flakes enabled

## Boot the Installer

1. Download a NixOS installer ISO from [nixos.org](https://nixos.org/download/)
2. Write it to USB: `dd if=nixos.iso of=/dev/sdX bs=4M status=progress`
3. Boot from the USB drive

## Clone nitrousOS

Once booted into the installer:

```bash
# Install git if not available
nix-env -iA nixpkgs.git nixpkgs.just

# Clone the repository
git clone https://github.com/yourusername/nitrousOS
cd nitrousOS
```

## Choose Your Target

| Target | Description |
|--------|-------------|
| `dinitrogen` | Full desktop with COSMIC DE |
| `oxide` | Minimal server (SSH + Tailscale) |
| `trixie` | Headscale coordination server |

## Run the Installer

```bash
# Install to your target disk
just install /dev/nvme0n1 dinitrogen
```

Replace `/dev/nvme0n1` with your actual disk device.

**WARNING**: This will erase all data on the target disk!

## What the Installer Creates

The installer creates four partitions with LUKS encryption:

```
NAME              SIZE  TYPE   MOUNTPOINT
nvme0n1           500G  disk
├─nvme0n1p1       512M  part   /boot        (NITROUSBOOT - FAT32 EFI)
├─nvme0n1p2       100G  part                (NITROUSROOT)
│ └─cryptroot     100G  crypt  /            (ext4)
├─nvme0n1p3       380G  part                (NITROUSHOME)
│ └─crypthome     380G  crypt  /home        (ext4)
└─nvme0n1p4        16G  part                (NITROUSSWAP)
  └─cryptswap      16G  crypt  [SWAP]       (swap)
```

### Partition Details

| Partition | Label | Size | Encryption | Purpose |
|-----------|-------|------|------------|---------|
| p1 | NITROUSBOOT | 512 MB | None | EFI system partition |
| p2 | NITROUSROOT | 100 GB | LUKS2 | Root filesystem |
| p3 | NITROUSHOME | Remaining - 16GB | LUKS2 | Home directory |
| p4 | NITROUSSWAP | 16 GB | LUKS2 | Encrypted swap |

## Installation Steps (Manual)

If you prefer manual installation or need customization:

### 1. Partition the Disk

```bash
# Using parted
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 513MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 513MiB 100.5GiB
parted /dev/nvme0n1 -- mkpart primary 100.5GiB -16GiB
parted /dev/nvme0n1 -- mkpart primary -16GiB 100%

# Label partitions
parted /dev/nvme0n1 -- name 1 NITROUSBOOT
parted /dev/nvme0n1 -- name 2 NITROUSROOT
parted /dev/nvme0n1 -- name 3 NITROUSHOME
parted /dev/nvme0n1 -- name 4 NITROUSSWAP
```

### 2. Set Up LUKS Encryption

```bash
# Encrypt root
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/NITROUSROOT
cryptsetup open /dev/disk/by-partlabel/NITROUSROOT cryptroot

# Encrypt home
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/NITROUSHOME
cryptsetup open /dev/disk/by-partlabel/NITROUSHOME crypthome

# Encrypt swap
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/NITROUSSWAP
cryptsetup open /dev/disk/by-partlabel/NITROUSSWAP cryptswap
```

### 3. Create Filesystems

```bash
mkfs.fat -F32 -n NITROUSBOOT /dev/disk/by-partlabel/NITROUSBOOT
mkfs.ext4 -L nixos /dev/mapper/cryptroot
mkfs.ext4 -L home /dev/mapper/crypthome
mkswap -L swap /dev/mapper/cryptswap
```

### 4. Mount Filesystems

```bash
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot /mnt/home
mount /dev/disk/by-partlabel/NITROUSBOOT /mnt/boot
mount /dev/mapper/crypthome /mnt/home
swapon /dev/mapper/cryptswap
```

### 5. Generate Hardware Configuration

```bash
nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/hardware-configuration.nix` with your hardware details.

### 6. Clone and Configure

```bash
cd /mnt/etc/nixos
git clone https://github.com/yourusername/nitrousOS
cd nitrousOS

# Copy hardware config
cp /mnt/etc/nixos/hardware-configuration.nix oem/hardware/my-hardware.nix
```

### 7. Create Your Target

Add to `flake.nix` in the OEM HARDWARE TARGETS section:

```nix
my-machine = nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./lib/system
    ./oem/profiles/dinitrogen  # or oxide/trixie
    ./oem/hardware/my-hardware.nix
    {
      nitrousOS.system = "dinitrogen";

      # LUKS devices
      boot.initrd.luks.devices = {
        cryptroot.device = "/dev/disk/by-partlabel/NITROUSROOT";
        crypthome.device = "/dev/disk/by-partlabel/NITROUSHOME";
        cryptswap.device = "/dev/disk/by-partlabel/NITROUSSWAP";
      };

      system.stateVersion = "25.11";
    }
  ];
};
```

### 8. Install

```bash
nixos-install --flake .#my-machine
```

### 9. Reboot

```bash
reboot
```

You'll be prompted for your LUKS passphrase at boot.

## Post-Installation

### Set User Password

After first boot:

```bash
passwd your-username
```

### Configure Tailscale (oxide/trixie)

```bash
sudo tailscale up
```

### Update the System

```bash
cd /etc/nixos/nitrousOS
sudo nix flake update
just switch my-machine
```

## Troubleshooting

### Boot Issues

If the system won't boot:

1. Boot from installer USB
2. Open LUKS devices:
   ```bash
   cryptsetup open /dev/disk/by-partlabel/NITROUSROOT cryptroot
   ```
3. Mount and chroot:
   ```bash
   mount /dev/mapper/cryptroot /mnt
   mount /dev/disk/by-partlabel/NITROUSBOOT /mnt/boot
   nixos-enter
   ```
4. Rebuild:
   ```bash
   nixos-rebuild switch --flake /etc/nixos/nitrousOS#my-machine
   ```

### LUKS Passphrase

If you forget your passphrase, data cannot be recovered. Consider:

- Using a key file stored securely
- Setting up multiple LUKS key slots

### Hardware Not Detected

Regenerate hardware configuration:

```bash
nixos-generate-config --root /mnt
```

Compare with your existing config and update as needed.
