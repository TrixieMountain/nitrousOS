# nitrousOS build commands
# Usage: just <action> <target>
# Actions: boot, test, switch, sandbox, iso, usb, check, update, targets
# Targets: dinitrogen, oxide, trixie

# Default target
default_target := "dinitrogen"

# Boot into the new configuration on next reboot (doesn't switch now)
boot target=default_target:
    sudo nixos-rebuild boot --flake .#{{target}}

# Test the configuration (activate but don't add to bootloader)
test target=default_target:
    sudo nixos-rebuild test --flake .#{{target}}

# Switch to the new configuration immediately
switch target=default_target:
    sudo nixos-rebuild switch --flake .#{{target}}

# Build and run in a VM (graphical)
sandbox target=default_target:
    nixos-rebuild build-vm --flake .#{{target}}
    ./result/bin/run-*-vm

# Build an ISO image
iso target=default_target:
    nix build .#nixosConfigurations.{{target}}.config.system.build.isoImage

# Build and write to USB (requires device path as argument)
usb target device:
    nix build .#nixosConfigurations.{{target}}.config.system.build.isoImage
    @echo "Writing ISO to {{device}}..."
    sudo dd if=result/iso/*.iso of={{device}} bs=4M status=progress oflag=sync

# Check flake for errors
check:
    nix flake check --no-build

# Update flake inputs
update:
    nix flake update

# Show available targets
targets:
    @echo "Available targets:"
    @echo "  dinitrogen - Full-featured desktop (flagship)"
    @echo "  oxide      - Minimal server/headless"
    @echo "  trixie     - Lightweight desktop"
