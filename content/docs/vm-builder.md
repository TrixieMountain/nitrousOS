---
title: "VM Builder"
description: "Build VM images for any virtualization platform or cloud provider"
weight: 5
---

nitrousOS includes a comprehensive VM builder that generates disk images in 8 different formats, ready for deployment on any platform.

## Quick Start

```bash
# Build all formats for a target
just build-vms oxide

# Output location
ls dist/vm/oxide/
```

## Output Formats

| Format | Extension | Platform | Command |
|--------|-----------|----------|---------|
| RAW | `.raw` | Direct disk image | `just build-raw` |
| QCOW2 | `.qcow2` | QEMU/KVM, Proxmox | `just qcow2` |
| VMDK | `.vmdk` | VMware ESXi, Workstation | `just vmdk` |
| VDI | `.vdi` | VirtualBox | `just vdi` |
| VHDX | `.vhdx` | Hyper-V | `just vhdx` |
| Azure VHD | `-azure.vhd` | Microsoft Azure | `just azure-vhd` |
| OVA | `.ova` | VMware, VirtualBox | `just make-ova` |
| AMI | `-ami.tar.gz` | AWS EC2 | `just make-ami` |

## Build Commands

### Build Everything

```bash
# Build all formats with checksums
just build-vms dinitrogen

# Output:
# dist/vm/dinitrogen/
# ├── dinitrogen.raw
# ├── dinitrogen.qcow2
# ├── dinitrogen.vmdk
# ├── dinitrogen.vdi
# ├── dinitrogen.vhdx
# ├── dinitrogen-azure.vhd
# ├── dinitrogen.ova
# ├── dinitrogen-ami.tar.gz
# ├── SHA256SUMS
# └── SHA256SUMS.sig (if GPG available)
```

### Build Individual Formats

```bash
# Just the RAW image
just build-raw oxide

# Convert to specific format (requires RAW first)
just qcow2 oxide
just vmdk oxide
just vdi oxide
```

### Verification

```bash
# Generate checksums
just checksums oxide

# GPG sign (requires GPG key)
just sign oxide
```

## Platform-Specific Instructions

### QEMU/KVM

```bash
just qcow2 oxide

# Run with QEMU
qemu-system-x86_64 \
  -enable-kvm \
  -m 2G \
  -cpu host \
  -drive file=dist/vm/oxide/oxide.qcow2,format=qcow2 \
  -net nic -net user,hostfwd=tcp::2222-:22
```

### Proxmox

1. Build QCOW2 image:
   ```bash
   just qcow2 oxide
   ```

2. Copy to Proxmox server:
   ```bash
   scp dist/vm/oxide/oxide.qcow2 root@proxmox:/var/lib/vz/images/
   ```

3. Import to VM:
   ```bash
   qm importdisk <vmid> /var/lib/vz/images/oxide.qcow2 local-lvm
   ```

### VMware ESXi/Workstation

```bash
just vmdk oxide
# or
just make-ova oxide
```

Import the `.ova` file directly, or attach the `.vmdk` to a new VM.

### VirtualBox

```bash
just vdi oxide
# or
just make-ova oxide
```

Import the `.ova` file or create a new VM with the `.vdi` disk.

### Hyper-V

```bash
just vhdx oxide
```

Create a new VM in Hyper-V Manager and attach the `.vhdx` disk.

### Microsoft Azure

```bash
just azure-vhd oxide
```

The Azure VHD is:
- Fixed-size format (required by Azure)
- 512-byte aligned (required by Azure)

Upload to Azure:
```bash
az storage blob upload \
  --account-name <storage-account> \
  --container-name vhds \
  --name oxide.vhd \
  --file dist/vm/oxide/oxide-azure.vhd \
  --type page
```

### AWS EC2

```bash
just make-ami oxide
```

Creates:
- `oxide-ami.tar.gz` - RAW image tarball
- `ami/import.json` - Import manifest template

Import to AWS:
```bash
# Edit ami/import.json with your S3 bucket
aws s3 cp dist/vm/oxide/oxide-ami.tar.gz s3://your-bucket/

aws ec2 import-image \
  --disk-containers file://dist/vm/oxide/ami/import.json
```

### Google Cloud Platform

```bash
just build-raw oxide

# Compress for GCP
gzip -c dist/vm/oxide/oxide.raw > dist/vm/oxide/oxide.tar.gz

# Upload to GCS
gsutil cp dist/vm/oxide/oxide.tar.gz gs://your-bucket/

# Create image
gcloud compute images create nitrous-oxide \
  --source-uri=gs://your-bucket/oxide.tar.gz
```

## Parallel Builds

Build multiple targets simultaneously:

```bash
just build-vms dinitrogen &
just build-vms oxide &
just build-vms trixie &
wait
```

## Verification

Always verify downloaded images:

```bash
cd dist/vm/oxide/
sha256sum -c SHA256SUMS
```

If GPG signed:
```bash
gpg --verify SHA256SUMS.sig SHA256SUMS
```

## Image Sizes

Approximate sizes (may vary):

| Target | RAW | QCOW2 |
|--------|-----|-------|
| Dinitrogen | ~11 GB | ~8 GB |
| Trixie | ~6 GB | ~4 GB |
| Oxide | ~5 GB | ~2 GB |

Oxide is the smallest as it includes no desktop environment.

## Customizing Images

### Disk Size

Edit `flake.nix` disk image configuration:

```nix
# In the -disk output
diskSize = "20G";  # Adjust as needed
```

### Additional Packages

Add packages to your profile before building:

```nix
environment.systemPackages = with pkgs; [
  your-packages
];
```

Then rebuild:
```bash
just build-vms your-target
```
