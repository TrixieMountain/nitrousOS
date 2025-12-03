# VM Builder Guide

nitrousOS includes a comprehensive VM image builder that generates disk images in multiple formats for cloud and virtualization platforms.

## Quick Start

```bash
# Build all formats for a target
just build-vms oxide

# Output in dist/vm/oxide/
```

## Output Formats

| Format | File | Platform |
|--------|------|----------|
| RAW | `<target>.raw` | Base image for all conversions |
| QCOW2 | `<target>.qcow2` | QEMU/KVM, Proxmox |
| VMDK | `<target>.vmdk` | VMware ESXi/Workstation |
| VDI | `<target>.vdi` | VirtualBox |
| VHDX | `<target>.vhdx` | Hyper-V |
| Azure VHD | `<target>-azure.vhd` | Microsoft Azure |
| OVA | `<target>.ova` | VMware/VirtualBox import |
| AMI | `<target>-ami.tar.gz` | AWS EC2 |

## Build Commands

### Full Build

Build all formats with checksums and GPG signatures:

```bash
just build-vms <target>
```

This runs:
1. `build-raw` - Generate RAW image from Nix
2. `convert-all` - Convert to QCOW2, VMDK, VDI, VHDX, Azure VHD
3. `make-ova` - Package OVA archive
4. `make-ami` - Create AWS AMI tarball
5. `checksums` - Generate SHA256SUMS
6. `sign` - GPG sign checksums

### Individual Formats

```bash
# Build only RAW image
just build-raw oxide

# Convert to specific format (requires RAW first)
just qcow2 oxide
just vmdk oxide
just vdi oxide
just vhdx oxide
just azure-vhd oxide

# Create OVA package
just make-ova oxide

# Create AMI tarball
just make-ami oxide

# Generate checksums
just checksums oxide

# Sign checksums
just sign oxide
```

## Output Directory

All output goes to `dist/vm/<target>/`:

```
dist/
└── vm/
    └── oxide/
        ├── raw-result -> /nix/store/...
        ├── oxide.raw
        ├── oxide.qcow2
        ├── oxide.vmdk
        ├── oxide.vdi
        ├── oxide.vhdx
        ├── oxide-azure.vhd
        ├── oxide.ovf
        ├── oxide.ova
        ├── oxide-ami.tar.gz
        ├── ami/
        │   └── import.json
        ├── SHA256SUMS
        └── SHA256SUMS.sig
```

## Platform-Specific Instructions

### QEMU/KVM

```bash
just build-raw oxide
just qcow2 oxide

# Run with QEMU
qemu-system-x86_64 \
  -enable-kvm \
  -m 2048 \
  -cpu host \
  -drive file=dist/vm/oxide/oxide.qcow2,format=qcow2 \
  -nic user,hostfwd=tcp::2222-:22
```

### Proxmox

1. Build QCOW2 image:
   ```bash
   just qcow2 oxide
   ```

2. Upload to Proxmox storage

3. Create VM and import disk:
   ```bash
   qm importdisk <vmid> oxide.qcow2 local-lvm
   ```

### VMware ESXi

1. Build VMDK:
   ```bash
   just vmdk oxide
   ```

2. Upload to datastore via vSphere client

3. Create VM and attach existing disk

### VMware Workstation/Fusion

1. Build OVA:
   ```bash
   just make-ova oxide
   ```

2. File → Open → Select OVA file

### VirtualBox

1. Build VDI or OVA:
   ```bash
   just vdi oxide
   # or
   just make-ova oxide
   ```

2. For VDI: Create VM and attach existing disk
3. For OVA: File → Import Appliance

### Hyper-V

1. Build VHDX:
   ```bash
   just vhdx oxide
   ```

2. Create new VM in Hyper-V Manager

3. Select "Use an existing virtual hard disk"

### Microsoft Azure

1. Build Azure VHD:
   ```bash
   just azure-vhd oxide
   ```

2. Upload to Azure Blob Storage:
   ```bash
   az storage blob upload \
     --account-name <storage_account> \
     --container-name vhds \
     --name oxide-azure.vhd \
     --type page \
     --file dist/vm/oxide/oxide-azure.vhd
   ```

3. Create image from VHD:
   ```bash
   az image create \
     --resource-group <rg> \
     --name nitrousOS-oxide \
     --os-type Linux \
     --source https://<storage>.blob.core.windows.net/vhds/oxide-azure.vhd
   ```

### AWS EC2

1. Build AMI tarball:
   ```bash
   just make-ami oxide
   ```

2. Upload to S3:
   ```bash
   aws s3 cp dist/vm/oxide/oxide-ami.tar.gz s3://your-bucket/
   ```

3. Edit the import manifest:
   ```bash
   # Update S3 bucket name in:
   dist/vm/oxide/ami/import.json
   ```

4. Import as snapshot:
   ```bash
   aws ec2 import-snapshot \
     --disk-container file://dist/vm/oxide/ami/import.json
   ```

5. Create AMI from snapshot

### Google Cloud Platform

1. Build RAW image:
   ```bash
   just build-raw oxide
   ```

2. Create tarball:
   ```bash
   cd dist/vm/oxide
   tar -czf oxide-gcp.tar.gz oxide.raw
   ```

3. Upload and create image:
   ```bash
   gsutil cp oxide-gcp.tar.gz gs://your-bucket/
   gcloud compute images create nitrousos-oxide \
     --source-uri gs://your-bucket/oxide-gcp.tar.gz
   ```

## Verification

Verify downloaded images:

```bash
cd dist/vm/oxide

# Verify checksums
sha256sum -c SHA256SUMS

# Verify GPG signature
gpg --verify SHA256SUMS.sig SHA256SUMS
```

## Customization

### Image Size

The disk image size is set to "auto" (fits content). To specify a size, modify `flake.nix`:

```nix
makeDiskImage = name: nixosConfig:
  import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
    inherit pkgs config;
    lib = pkgs.lib;
    diskSize = "20480";  # 20GB in MB
    format = "raw";
    partitionTableType = "efi";
  };
```

### OVF Customization

The OVF descriptor in `make-ovf` sets defaults:
- 2 vCPUs
- 4 GB RAM
- 20 GB disk

Modify the `make-ovf` recipe in `justfile` to change these values.

## Parallel Builds

Different targets can be built in parallel safely:

```bash
# Build all three targets simultaneously
just build-vms dinitrogen &
just build-vms oxide &
just build-vms trixie &
wait
```

Each target outputs to its own subdirectory in `dist/vm/`.

## Cleaning Up

Remove all build artifacts:

```bash
just clean
```

This removes the entire `dist/` directory.

## Troubleshooting

### Build Fails

1. Ensure the target exists:
   ```bash
   just targets
   ```

2. Check flake is valid:
   ```bash
   just check
   ```

3. Try building the RAW image first:
   ```bash
   just build-raw <target>
   ```

### Conversion Fails

Ensure `qemu-img` is installed:
```bash
nix-env -iA nixpkgs.qemu
```

### GPG Signing Fails

Ensure you have a GPG key configured:
```bash
gpg --list-keys
```

Generate a key if needed:
```bash
gpg --full-generate-key
```

### Large Image Sizes

The "auto" disk size creates minimal images. If you need more space after deployment:

1. Resize the disk in your hypervisor
2. Boot the VM
3. Resize the partition and filesystem:
   ```bash
   sudo growpart /dev/sda 2
   sudo resize2fs /dev/sda2
   ```
