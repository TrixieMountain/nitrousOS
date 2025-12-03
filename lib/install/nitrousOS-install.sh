#!/usr/bin/env bash
#
# nitrousOS Install Script
# Creates LUKS-encrypted partition layout and installs nitrousOS
#
# Layout:
#   /dev/XXX1 - NITROUSBOOT (FAT32, EFI, 2GB)
#   /dev/XXX2 - NITROUSROOT (LUKS -> ext4, /)
#   /dev/XXX3 - NITROUSHOME (LUKS -> ext4, /home)
#   /dev/XXX4 - NITROUSSWAP (LUKS -> swap)
#
# Usage: nitrousOS-install <device> <flake-target>
# Example: nitrousOS-install /dev/nvme0n1 justin-p14s

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[nitrousOS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
ask() { echo -e "${BLUE}[?]${NC} $1"; }

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

DEVICE="${1:-}"
FLAKE_TARGET="${2:-}"
FLAKE_PATH="${FLAKE_PATH:-/mnt/etc/nixos}"

BOOT_SIZE="2GiB"
SWAP_SIZE="8GiB"
HOME_SIZE="50%"  # Of remaining space after boot/swap/root-min
ROOT_MIN="100GiB"

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------

if [[ -z "$DEVICE" ]]; then
    echo "Usage: nitrousOS-install <device> <flake-target>"
    echo ""
    echo "Devices:"
    lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
    echo ""
    echo "Flake targets: dinitrogen, oxide, trixie, justin-p14s, etc."
    exit 1
fi

if [[ -z "$FLAKE_TARGET" ]]; then
    error "Flake target required. Example: nitrousOS-install /dev/nvme0n1 justin-p14s"
fi

if [[ ! -b "$DEVICE" ]]; then
    error "Device $DEVICE does not exist"
fi

if [[ $EUID -ne 0 ]]; then
    error "Must run as root"
fi

# Detect partition suffix (nvme uses p1, sda uses 1)
if [[ "$DEVICE" == *"nvme"* ]] || [[ "$DEVICE" == *"mmcblk"* ]]; then
    PART_PREFIX="${DEVICE}p"
else
    PART_PREFIX="${DEVICE}"
fi

PART_BOOT="${PART_PREFIX}1"
PART_ROOT="${PART_PREFIX}2"
PART_HOME="${PART_PREFIX}3"
PART_SWAP="${PART_PREFIX}4"

# -----------------------------------------------------------------------------
# Confirmation
# -----------------------------------------------------------------------------

echo ""
echo "=============================================="
echo "         nitrousOS Installation"
echo "=============================================="
echo ""
echo "Device:       $DEVICE"
echo "Target:       $FLAKE_TARGET"
echo ""
echo "Partition layout:"
echo "  ${PART_BOOT}  NITROUSBOOT  ${BOOT_SIZE}   FAT32 (EFI)"
echo "  ${PART_ROOT}  NITROUSROOT  remaining  LUKS -> ext4 (/)"
echo "  ${PART_HOME}  NITROUSHOME  ${HOME_SIZE}      LUKS -> ext4 (/home)"
echo "  ${PART_SWAP}  NITROUSSWAP  ${SWAP_SIZE}   LUKS -> swap"
echo ""
warn "THIS WILL DESTROY ALL DATA ON $DEVICE"
echo ""
ask "Type 'yes' to continue:"
read -r CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# -----------------------------------------------------------------------------
# Partitioning
# -----------------------------------------------------------------------------

log "Partitioning $DEVICE..."

# Wipe existing partition table
wipefs -af "$DEVICE"

# Create GPT partition table
parted -s "$DEVICE" mklabel gpt

# Create partitions
parted -s "$DEVICE" mkpart NITROUSBOOT fat32 1MiB "$BOOT_SIZE"
parted -s "$DEVICE" set 1 esp on

parted -s "$DEVICE" mkpart NITROUSSWAP linux-swap "$BOOT_SIZE" "$((${BOOT_SIZE%GiB} + ${SWAP_SIZE%GiB}))GiB"

parted -s "$DEVICE" mkpart NITROUSHOME ext4 "$((${BOOT_SIZE%GiB} + ${SWAP_SIZE%GiB}))GiB" "60%"

parted -s "$DEVICE" mkpart NITROUSROOT ext4 "60%" "100%"

# Wait for partitions to appear
sleep 2
partprobe "$DEVICE"
sleep 2

log "Partitions created:"
lsblk "$DEVICE"

# -----------------------------------------------------------------------------
# LUKS Encryption
# -----------------------------------------------------------------------------

log "Setting up LUKS encryption..."

ask "Enter encryption passphrase for ROOT partition:"
cryptsetup luksFormat --type luks2 --label NITROUSROOT "$PART_ROOT"

ask "Enter encryption passphrase for HOME partition (or same as root):"
cryptsetup luksFormat --type luks2 --label NITROUSHOME "$PART_HOME"

ask "Enter encryption passphrase for SWAP partition (or same as root):"
cryptsetup luksFormat --type luks2 --label NITROUSSWAP "$PART_SWAP"

# Get UUIDs
UUID_ROOT=$(blkid -s UUID -o value "$PART_ROOT")
UUID_HOME=$(blkid -s UUID -o value "$PART_HOME")
UUID_SWAP=$(blkid -s UUID -o value "$PART_SWAP")

log "Opening LUKS volumes..."

ask "Enter passphrase to open ROOT:"
cryptsetup open "$PART_ROOT" "luks-${UUID_ROOT}"

ask "Enter passphrase to open HOME:"
cryptsetup open "$PART_HOME" "luks-${UUID_HOME}"

ask "Enter passphrase to open SWAP:"
cryptsetup open "$PART_SWAP" "luks-${UUID_SWAP}"

# -----------------------------------------------------------------------------
# Filesystem Creation
# -----------------------------------------------------------------------------

log "Creating filesystems..."

mkfs.fat -F 32 -n NITROUSBOOT "$PART_BOOT"
mkfs.ext4 -L NITROUSROOT "/dev/mapper/luks-${UUID_ROOT}"
mkfs.ext4 -L NITROUSHOME "/dev/mapper/luks-${UUID_HOME}"
mkswap -L NITROUSSWAP "/dev/mapper/luks-${UUID_SWAP}"

# -----------------------------------------------------------------------------
# Mounting
# -----------------------------------------------------------------------------

log "Mounting filesystems..."

mount "/dev/mapper/luks-${UUID_ROOT}" /mnt
mkdir -p /mnt/boot /mnt/home

mount "$PART_BOOT" /mnt/boot
mount "/dev/mapper/luks-${UUID_HOME}" /mnt/home
swapon "/dev/mapper/luks-${UUID_SWAP}"

log "Mounted filesystems:"
df -h /mnt /mnt/boot /mnt/home

# -----------------------------------------------------------------------------
# Generate Hardware Configuration
# -----------------------------------------------------------------------------

log "Generating hardware configuration..."

mkdir -p /mnt/etc/nixos
nixos-generate-config --root /mnt

# -----------------------------------------------------------------------------
# Output LUKS configuration
# -----------------------------------------------------------------------------

cat <<EOF

============================================
LUKS Configuration for flake.nix
============================================

Add this to your OEM hardware target:

boot.initrd.luks.devices = {
  "luks-${UUID_ROOT}" = {
    device = "/dev/disk/by-uuid/${UUID_ROOT}";
  };
  "luks-${UUID_HOME}" = {
    device = "/dev/disk/by-uuid/${UUID_HOME}";
  };
  "luks-${UUID_SWAP}" = {
    device = "/dev/disk/by-uuid/${UUID_SWAP}";
  };
};

============================================
EOF

# -----------------------------------------------------------------------------
# Install
# -----------------------------------------------------------------------------

ask "Proceed with nixos-install? (yes/no)"
read -r DO_INSTALL

if [[ "$DO_INSTALL" == "yes" ]]; then
    log "Installing nitrousOS ($FLAKE_TARGET)..."

    # If flake exists in repo, use it; otherwise expect user to provide
    if [[ -d "$FLAKE_PATH" ]]; then
        nixos-install --flake "${FLAKE_PATH}#${FLAKE_TARGET}"
    else
        warn "No flake found at $FLAKE_PATH"
        warn "Run manually: nixos-install --flake /path/to/nitrousOS#${FLAKE_TARGET}"
    fi
else
    log "Skipping nixos-install. Run manually when ready:"
    echo "  nixos-install --flake /path/to/nitrousOS#${FLAKE_TARGET}"
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------

echo ""
log "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Review /mnt/etc/nixos/hardware-configuration.nix"
echo "  2. Add LUKS devices to your flake target (see above)"
echo "  3. Reboot and enjoy nitrousOS!"
echo ""
