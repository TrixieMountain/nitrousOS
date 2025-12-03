# nitrousOS Build System
#
# Usage: just <recipe> [target]
# Run `just help` for details

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Configuration
default_target := "dinitrogen"
distdir := "dist"
name := "nitrous"
version := "dev"

# ═══════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════

[private]
default:
    @just help

# Show help
help:
    @echo ""
    @echo "  ┌─────────────────────────────────────────────────────────────┐"
    @echo "  │                   nitrousOS Build System                    │"
    @echo "  └─────────────────────────────────────────────────────────────┘"
    @echo ""
    @echo "  Usage: just <recipe> [target]"
    @echo ""
    @echo "  ┌─ System Commands ───────────────────────────────────────────┐"
    @echo "  │                                                             │"
    @echo "  │  install <dev> <tgt> Install to disk (LUKS encrypted)       │"
    @echo "  │  switch [target]     Build, activate, and add to bootloader │"
    @echo "  │  boot [target]       Build and set for next reboot          │"
    @echo "  │  test [target]       Build and activate (no boot entry)     │"
    @echo "  │  sandbox [target]    Build and run in QEMU VM               │"
    @echo "  │  iso [target]        Build bootable ISO image               │"
    @echo "  │  usb <target> <dev>  Build ISO and write to USB device      │"
    @echo "  │                                                             │"
    @echo "  └─────────────────────────────────────────────────────────────┘"
    @echo ""
    @echo "  ┌─ Targets ────────────────────────────────────────────────────┐"
    @echo "  │                                                             │"
    @echo "  │  VM Targets (generic):                                      │"
    @echo "  │    dinitrogen-vm     Full-featured desktop                  │"
    @echo "  │    oxide-vm          Server base (SSH + Tailscale)          │"
    @echo "  │    trixie-vm         Headscale coordination server AIO      │"
    @echo "  │                                                             │"
    @echo "  │  OEM Hardware:                                              │"
    @echo "  │    justin-p14s       Lenovo P14s + NVIDIA (dinitrogen)      │"
    @echo "  │                                                             │"
    @echo "  │  Aliases:                                                   │"
    @echo "  │    dinitrogen/oxide/trixie -> *-vm                          │"
    @echo "  │    nitrousOS -> justin-p14s                                 │"
    @echo "  │                                                             │"
    @echo "  └─────────────────────────────────────────────────────────────┘"
    @echo ""
    @echo "  ┌─ Utilities ─────────────────────────────────────────────────┐"
    @echo "  │                                                             │"
    @echo "  │  check               Validate flake syntax                  │"
    @echo "  │  update              Update all flake inputs                │"
    @echo "  │  targets             List available targets                 │"
    @echo "  │  clean               Remove all build artifacts (dist/)     │"
    @echo "  │                                                             │"
    @echo "  └─────────────────────────────────────────────────────────────┘"
    @echo ""
    @echo "  ┌─ VM Builder (outputs to dist/vm/<target>/) ─────────────────┐"
    @echo "  │                                                             │"
    @echo "  │  build-vms [target]  Build all formats + checksums + sign   │"
    @echo "  │  build-raw [target]  Build RAW disk image                   │"
    @echo "  │  ─────────────────────────────────────────────────────────  │"
    @echo "  │  qcow2 [target]      Convert to QCOW2 (QEMU/KVM)            │"
    @echo "  │  vmdk [target]       Convert to VMDK (VMware)               │"
    @echo "  │  vdi [target]        Convert to VDI (VirtualBox)            │"
    @echo "  │  vhdx [target]       Convert to VHDX (Hyper-V)              │"
    @echo "  │  azure-vhd [target]  Convert to Azure VHD (fixed, aligned)  │"
    @echo "  │  ─────────────────────────────────────────────────────────  │"
    @echo "  │  make-ova [target]   Package as OVA                         │"
    @echo "  │  make-ami [target]   Create AWS AMI tarball + manifest      │"
    @echo "  │  ─────────────────────────────────────────────────────────  │"
    @echo "  │  checksums [target]  Generate SHA256SUMS                    │"
    @echo "  │  sign [target]       GPG sign SHA256SUMS                    │"
    @echo "  │                                                             │"
    @echo "  └─────────────────────────────────────────────────────────────┘"
    @echo ""
    @echo "  Examples:"
    @echo "    just install /dev/nvme0n1 justin-p14s   Install to NVMe"
    @echo "    just switch justin-p14s                 Switch physical machine"
    @echo "    just sandbox oxide-vm                   Test oxide in QEMU"
    @echo "    just build-vms trixie                   Build trixie disk images"
    @echo ""

# Show available targets
[group('utility')]
targets:
    @echo "Available targets:"
    @echo ""
    @echo "  VM Targets (generic):"
    @echo "    dinitrogen-vm    Full-featured desktop"
    @echo "    oxide-vm         Server base (SSH + Tailscale)"
    @echo "    trixie-vm        Headscale coordination server AIO"
    @echo ""
    @echo "  OEM Hardware Targets:"
    @echo "    justin-p14s      Lenovo P14s with NVIDIA (dinitrogen)"
    @echo ""
    @echo "  Aliases (point to VM targets):"
    @echo "    dinitrogen       -> dinitrogen-vm"
    @echo "    oxide            -> oxide-vm"
    @echo "    trixie           -> trixie-vm"
    @echo "    nitrousOS        -> justin-p14s (legacy)"

# ═══════════════════════════════════════════════════════════════════
# SYSTEM COMMANDS
# ═══════════════════════════════════════════════════════════════════

# Install nitrousOS to a physical disk (LUKS encrypted)
[group('system')]
install device target:
    sudo ./lib/install/nitrousOS-install.sh {{device}} {{target}}

# Switch to the new configuration immediately
[group('system')]
switch target=default_target:
    sudo nixos-rebuild switch --flake .#{{target}}

# Boot into the new configuration on next reboot
[group('system')]
boot target=default_target:
    sudo nixos-rebuild boot --flake .#{{target}}

# Test the configuration (activate but don't add to bootloader)
[group('system')]
test target=default_target:
    sudo nixos-rebuild test --flake .#{{target}}

# Build and run in a VM (graphical)
[group('system')]
sandbox target=default_target:
    mkdir -p {{distdir}}/sandbox/{{target}}
    nix build .#nixosConfigurations.{{target}}.config.system.build.vm --out-link {{distdir}}/sandbox/{{target}}/result
    {{distdir}}/sandbox/{{target}}/result/bin/run-*-vm

# Build an ISO image
[group('system')]
iso target=default_target:
    mkdir -p {{distdir}}/iso/{{target}}
    nix build .#nixosConfigurations.{{target}}.config.system.build.isoImage --out-link {{distdir}}/iso/{{target}}/result

# Build and write to USB (requires device path)
[group('system')]
usb target device:
    mkdir -p {{distdir}}/iso/{{target}}
    nix build .#nixosConfigurations.{{target}}.config.system.build.isoImage --out-link {{distdir}}/iso/{{target}}/result
    @echo "Writing ISO to {{device}}..."
    sudo dd if={{distdir}}/iso/{{target}}/result/iso/*.iso of={{device}} bs=4M status=progress oflag=sync

# ═══════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════

# Check flake for errors
[group('utility')]
check:
    nix flake check --no-build

# Update flake inputs
[group('utility')]
update:
    nix flake update

# Clean all build artifacts
[group('utility')]
clean:
    rm -rf {{distdir}}
    @echo "✔ Cleaned {{distdir}}/"

# ═══════════════════════════════════════════════════════════════════
# VM BUILDER
# ═══════════════════════════════════════════════════════════════════

# Build all VM formats with checksums and signatures
[group('vm')]
build-vms target=default_target: (build-raw target) (convert-all target) (make-ova target) (make-ami target) (checksums target) (sign target)
    @echo "✔ All VM artifacts built in {{distdir}}/vm/{{target}}/"

# Build RAW image from flake
[group('vm')]
build-raw target=default_target:
    mkdir -p {{distdir}}/vm/{{target}}
    nix build .#{{target}}-disk --out-link {{distdir}}/vm/{{target}}/raw-result
    cp {{distdir}}/vm/{{target}}/raw-result/nixos.img {{distdir}}/vm/{{target}}/{{target}}.raw
    @echo "✔ RAW image built: {{distdir}}/vm/{{target}}/{{target}}.raw"

# Convert to all formats (parallel-safe)
[group('vm')]
convert-all target=default_target: (qcow2 target) (vmdk target) (vdi target) (vhdx target) (azure-vhd target)

# Convert to QCOW2 (QEMU/KVM)
[group('vm')]
qcow2 target=default_target:
    qemu-img convert -O qcow2 {{distdir}}/vm/{{target}}/{{target}}.raw {{distdir}}/vm/{{target}}/{{target}}.qcow2
    @echo "✔ QCOW2 generated: {{distdir}}/vm/{{target}}/{{target}}.qcow2"

# Convert to VMDK (VMware)
[group('vm')]
vmdk target=default_target:
    qemu-img convert -O vmdk {{distdir}}/vm/{{target}}/{{target}}.raw {{distdir}}/vm/{{target}}/{{target}}.vmdk
    @echo "✔ VMDK generated: {{distdir}}/vm/{{target}}/{{target}}.vmdk"

# Convert to VDI (VirtualBox)
[group('vm')]
vdi target=default_target:
    qemu-img convert -O vdi {{distdir}}/vm/{{target}}/{{target}}.raw {{distdir}}/vm/{{target}}/{{target}}.vdi
    @echo "✔ VDI generated: {{distdir}}/vm/{{target}}/{{target}}.vdi"

# Convert to VHDX (Hyper-V)
[group('vm')]
vhdx target=default_target:
    qemu-img convert -O vhdx {{distdir}}/vm/{{target}}/{{target}}.raw {{distdir}}/vm/{{target}}/{{target}}.vhdx
    @echo "✔ VHDX generated: {{distdir}}/vm/{{target}}/{{target}}.vhdx"

# Convert to Azure VHD (fixed-size, aligned)
[group('vm')]
azure-vhd target=default_target:
    qemu-img convert -O vpc -o subformat=fixed,force_size {{distdir}}/vm/{{target}}/{{target}}.raw {{distdir}}/vm/{{target}}/{{target}}-azure.vhd
    python3 -c 'import os; p="{{distdir}}/vm/{{target}}/{{target}}-azure.vhd"; s=os.path.getsize(p); rem=s%512; open(p,"ab").write(b"\x00"*(512-rem)) if rem else None'
    @echo "✔ Azure VHD generated: {{distdir}}/vm/{{target}}/{{target}}-azure.vhd"

# Create OVA package (VMware/VirtualBox)
[group('vm')]
make-ova target=default_target: (make-ovf target)
    tar cvf {{distdir}}/vm/{{target}}/{{target}}.ova -C {{distdir}}/vm/{{target}} {{target}}.ovf {{target}}.vmdk
    @echo "✔ OVA package created: {{distdir}}/vm/{{target}}/{{target}}.ova"

[private]
make-ovf target=default_target:
    printf '%s\n' '<Envelope ovf:version="1.0" xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1" xmlns:rasd="http://schemas.dmtf.org/ovf/envelope/1"><VirtualSystem ovf:id="{{target}}"><VirtualHardwareSection><Item><rasd:ResourceType>3</rasd:ResourceType><rasd:VirtualQuantity>2</rasd:VirtualQuantity></Item><Item><rasd:ResourceType>4</rasd:ResourceType><rasd:VirtualQuantity>4096</rasd:VirtualQuantity></Item></VirtualHardwareSection></VirtualSystem><DiskSection><Disk ovf:diskId="disk1" ovf:fileRef="{{target}}.vmdk" ovf:capacity="20GB" /></DiskSection></Envelope>' > {{distdir}}/vm/{{target}}/{{target}}.ovf
    @echo "✔ OVF descriptor created"

# Create AWS AMI tarball and manifest
[group('vm')]
make-ami target=default_target:
    mkdir -p {{distdir}}/vm/{{target}}/ami
    tar czf {{distdir}}/vm/{{target}}/{{target}}-ami.tar.gz -C {{distdir}}/vm/{{target}} {{target}}.raw
    printf '%s\n' '{"Description":"NitrousOS {{target}} AMI image (RAW)","Format":"raw","UserBucket":{"S3Bucket":"YOUR-BUCKET-HERE","S3Key":"{{target}}-ami.tar.gz"}}' > {{distdir}}/vm/{{target}}/ami/import.json
    @echo "✔ AMI tarball created: {{distdir}}/vm/{{target}}/{{target}}-ami.tar.gz"

# Generate SHA256 checksums
[group('vm')]
checksums target=default_target:
    cd {{distdir}}/vm/{{target}} && sha256sum {{target}}.raw {{target}}.qcow2 {{target}}.vmdk {{target}}.vdi {{target}}.vhdx {{target}}-azure.vhd {{target}}.ova {{target}}-ami.tar.gz > SHA256SUMS
    @echo "✔ SHA256SUMS generated: {{distdir}}/vm/{{target}}/SHA256SUMS"

# GPG sign the checksums file
[group('vm')]
sign target=default_target:
    gpg --armor --output {{distdir}}/vm/{{target}}/SHA256SUMS.sig --sign {{distdir}}/vm/{{target}}/SHA256SUMS
    @echo "✔ SHA256SUMS signed: {{distdir}}/vm/{{target}}/SHA256SUMS.sig"
