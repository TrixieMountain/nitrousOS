---
title: "Configuration"
description: "Configure nitrousOS system options, plugins, and user profiles"
weight: 3
---

## System Variants

Select your system variant in the flake target or via attribute:

```nix
{ nitrousOS.system = "dinitrogen"; }  # or "oxide" or "trixie"
```

Each variant has different defaults for core modules and plugins.

## Core Modules

Core modules provide essential system functionality. All are located in `lib/core/`:

| Module | File | Description |
|--------|------|-------------|
| Boot | `boot.nix` | systemd-boot configuration |
| Locale | `locale.nix` | Timezone and locale settings |
| Audio | `audio.nix` | PipeWire audio stack |
| Services | `services.nix` | Printing, libinput |
| Nix | `nix.nix` | Flakes, unfree packages, auto-upgrade |

Configure in your profile:

```nix
# Boot configuration
nitrousOS.core.boot.enable = true;

# Locale settings
nitrousOS.core.locale.enable = true;
nitrousOS.core.locale.timeZone = "America/New_York";

# Audio (PipeWire)
nitrousOS.core.audio.enable = true;

# Base services (printing, libinput)
nitrousOS.core.services.enable = true;
nitrousOS.core.services.printing = true;  # Can disable for servers

# Nix settings
nitrousOS.core.nix.enable = true;
nitrousOS.core.nix.allowUnfree = true;  # Default: true
nitrousOS.core.nix.autoUpgrade.enable = true;
nitrousOS.core.nix.autoUpgrade.allowReboot = true;
nitrousOS.core.nix.autoUpgrade.channel = "https://channels.nixos.org/nixos-25.11";
```

### Defaults by System Variant

| Option | Dinitrogen | Oxide | Trixie |
|--------|------------|-------|--------|
| `core.audio.enable` | true | **false** | true |
| `core.services.printing` | true | **false** | true |
| `core.nix.autoUpgrade.enable` | **true** | false | false |
| `core.nix.autoUpgrade.allowReboot` | **true** | false | false |

## Plugin System

Plugins add optional functionality. Enable them as needed:

### Desktop Environments

```nix
# COSMIC (recommended for dinitrogen)
nitrousOS.plugin.desktop.cosmic.enable = true;

# Or choose another:
# nitrousOS.plugin.desktop.gnome.enable = true;
# nitrousOS.plugin.desktop.kde.enable = true;
# nitrousOS.plugin.desktop.pantheon.enable = true;
```

### Dynamic GPU Control

For laptops with hybrid NVIDIA/Intel graphics (`lib/plugin/dynamic-gpu.nix`):

```nix
nitrousOS.plugin.dynamicGpu = {
  enable = true;
  defaultMode = "igpu-only";  # or "auto" or "dgpu-forced"
  disableMethod = "auto";     # or "pci-remove" or "acpi-off"
};
```

**Modes:**

| Mode | Description | Use Case |
|------|-------------|----------|
| `auto` | Switches based on external display/dock | Daily use |
| `igpu-only` | Integrated GPU only | Battery saving |
| `dgpu-forced` | Discrete GPU always on | Gaming, rendering |

**Disable Methods:**

| Method | Description |
|--------|-------------|
| `auto` | Auto-detects ThinkPad → ACPI, others → PCI remove |
| `acpi-off` | Uses ACPI `_OFF` call (ThinkPads, some Lenovos) |
| `pci-remove` | Removes GPU from PCI bus |

**CLI Commands:**
- `gpu-mode auto` - Automatic switching based on display/dock
- `gpu-mode igpu` - Integrated GPU only (power saving)
- `gpu-mode dgpu` - Force discrete GPU
- `nvidia-offload <command>` - Run single command on discrete GPU

**Automatic Detection:**
- External monitors via DRM status
- Thunderbolt docks
- ThinkPad-specific ACPI paths

### Software Categories

Enable software packages by category (`lib/plugin/software.nix`):

```nix
nitrousOS.software.enable = true;

# Core utilities
nitrousOS.software.core.enable = true;

# Browsers
nitrousOS.software.browsers.enable = true;

# Security tools
nitrousOS.software.security.enable = true;

# Communication
nitrousOS.software.communication.enable = true;

# Development tools
nitrousOS.software.dev.enable = true;

# Pantheon/Elementary apps
nitrousOS.software.pantheon.enable = true;
```

**Default Packages by Category:**

| Category | Packages |
|----------|----------|
| `core` | wget, vim, git, just, VSCodium |
| `browsers` | Firefox, Chromium, Mullvad Browser |
| `security` | KeePassXC, Mullvad VPN, ClamAV, Tailscale |
| `communication` | Signal Desktop, Thunderbird |
| `dev` | Claude Code, Hardinfo2 |
| `pantheon` | All Elementary/Pantheon apps (auto-discovered) |

**Custom Packages:**

Override default packages for any category:

```nix
nitrousOS.software.browsers = {
  enable = true;
  packages = with pkgs; [ firefox brave ];  # Custom browser list
};
```

## User Profiles

User profiles are defined in `oem/user/` and auto-imported. They support conditional activation based on system variant.

### Structure

```nix
# oem/user/myuser.nix
{ config, pkgs, lib, ... }:

let
  # Only enable this user on specific systems
  enableForSystems = [ "dinitrogen" ];
  enabled = builtins.elem (config.nitrousOS.system or "") enableForSystems;
in
{
  config = lib.mkIf enabled {
    users.users.myuser = {
      isNormalUser = true;
      description = "My User";
      extraGroups = [ "networkmanager" "wheel" ];
    };

    # User-specific software
    nitrousOS.software.enable = true;
    nitrousOS.software.browsers.enable = true;
  };
}
```

### Example: Desktop User

```nix
# oem/user/justin.nix
{ config, pkgs, lib, ... }:

let
  enableForSystems = [ "dinitrogen" ];
  enabled = builtins.elem (config.nitrousOS.system or "") enableForSystems;
in
{
  config = lib.mkIf enabled {
    users.users.justin = {
      isNormalUser = true;
      description = "Justin";
      extraGroups = [ "networkmanager" "wheel" ];
    };

    # Auto-login
    services.displayManager.autoLogin.enable = true;
    services.displayManager.autoLogin.user = "justin";

    # Full software suite
    nitrousOS.software.enable = true;
    nitrousOS.software.core.enable = true;
    nitrousOS.software.browsers.enable = true;
    nitrousOS.software.security.enable = true;
    nitrousOS.software.communication.enable = true;
    nitrousOS.software.dev.enable = true;
    nitrousOS.software.pantheon.enable = true;
  };
}
```

### Example: Server Admin

```nix
# oem/user/admin.nix
{ config, pkgs, lib, ... }:

let
  enableForSystems = [ "oxide" "trixie" ];
  enabled = builtins.elem (config.nitrousOS.system or "") enableForSystems;
in
{
  config = lib.mkIf enabled {
    users.users.admin = {
      isNormalUser = true;
      description = "Admin";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAA... admin@example.com"
      ];
    };
  };
}
```

## Adding Custom Targets

### VM Target

Add to `flake.nix` in the VM TARGETS section:

```nix
my-custom-vm = nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./lib/system
    ./oem/profiles/my-custom
    ./oem/user
    ({ modulesPath, ... }: {
      imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
      nitrousOS.system = "oxide";
      system.stateVersion = "25.11";
      fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
      boot.loader.grub.device = "/dev/sda";
    })
  ];
};
```

### Hardware Target

Add to `flake.nix` in the OEM HARDWARE TARGETS section:

```nix
my-laptop = nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./lib/system
    ./oem/profiles/dinitrogen
    ./oem/user
    ./oem/hardware/my-laptop.nix
    {
      nitrousOS.system = "dinitrogen";
      boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/...";
      system.stateVersion = "25.11";
    }
  ];
};
```
