# Configuration Guide

nitrousOS uses a modular configuration system with core modules, plugins, and software categories.

## Architecture Overview

```
nitrousOS/
├── lib/
│   ├── core/           # Essential system components
│   │   ├── boot.nix    # Bootloader (systemd-boot)
│   │   ├── locale.nix  # Timezone, locale
│   │   ├── audio.nix   # PipeWire audio
│   │   ├── services.nix # Base services
│   │   └── nix.nix     # Nix settings
│   ├── plugin/         # Optional features
│   │   ├── desktop/    # Desktop environments
│   │   ├── network/    # Network configuration
│   │   ├── software.nix # Package categories
│   │   └── dynamic-gpu.nix # Hybrid GPU control
│   └── system/         # System variants
│       ├── dinitrogen/ # Full desktop
│       ├── oxide/      # Server base
│       └── trixie/     # Headscale AIO
└── oem/
    ├── profiles/       # System profiles (network, services, desktop)
    ├── user/           # User definitions (credentials, software)
    └── hardware/       # Machine-specific configs
```

## System Variant

Select your base system variant:

```nix
{
  nitrousOS.system = "dinitrogen";  # or "oxide" or "trixie"
}
```

| Variant | Description |
|---------|-------------|
| `dinitrogen` | Full desktop (COSMIC, Pantheon, GNOME, or KDE) |
| `oxide` | Minimal server base |
| `trixie` | Headscale coordination server |

## Core Options

Core modules provide essential system functionality.

### Boot (`nitrousOS.core.boot`)

```nix
{
  nitrousOS.core.boot.enable = true;  # Default: true
}
```

Configures systemd-boot with sensible defaults.

### Locale (`nitrousOS.core.locale`)

```nix
{
  nitrousOS.core.locale = {
    enable = true;
    timeZone = "America/New_York";
    defaultLocale = "en_US.UTF-8";
  };
}
```

### Audio (`nitrousOS.core.audio`)

```nix
{
  nitrousOS.core.audio.enable = true;  # Enables PipeWire
}
```

### Nix Settings (`nitrousOS.core.nix`)

```nix
{
  nitrousOS.core.nix = {
    enable = true;
    autoUpgrade.enable = true;
  };
}
```

Enables flakes, unfree packages, and automatic garbage collection.

## Plugin Options

Plugins provide optional features that can be enabled per-profile.

### Desktop Environments

Enable one desktop environment:

```nix
# COSMIC (recommended for dinitrogen)
{
  nitrousOS.plugin.desktop.cosmic.enable = true;
}

# GNOME
{
  nitrousOS.plugin.desktop.gnome.enable = true;
}

# KDE Plasma
{
  nitrousOS.plugin.desktop.kde.enable = true;
}

# Pantheon (elementary OS style)
{
  nitrousOS.plugin.desktop.pantheon.enable = true;
}
```

### Dynamic GPU Control

For laptops with hybrid NVIDIA/Intel graphics:

```nix
{
  nitrousOS.plugin.dynamicGpu = {
    enable = true;
    defaultMode = "auto";       # auto | igpu-only | dgpu-forced
    disableMethod = "auto";     # auto | pci-remove | acpi-off
  };
}
```

**Modes:**
- `auto` - Enable dGPU only when external display or dock is connected
- `igpu-only` - Always use integrated graphics (power saving)
- `dgpu-forced` - Always enable discrete GPU

**CLI Commands:**
```bash
# Switch GPU mode
gpu-mode auto     # Automatic switching
gpu-mode igpu     # Force integrated only
gpu-mode dgpu     # Force discrete GPU

# Run application on discrete GPU
nvidia-offload <command>
```

### Network Configuration

```nix
{
  nitrousOS.plugin.network = {
    enable = true;
    # Additional network options
  };
}
```

## Software Categories

Enable software packages by category:

```nix
{
  nitrousOS.software = {
    enable = true;

    core.enable = true;           # wget, vim, git, just, vscodium
    browsers.enable = true;       # firefox, chromium, mullvad-browser
    security.enable = true;       # keepassxc, mullvad, clamav, tailscale
    communication.enable = true;  # signal-desktop, thunderbird
    dev.enable = true;            # claude-code, hardinfo2
    pantheon.enable = true;       # Pantheon/elementary apps
  };
}
```

### Custom Packages

Override or extend package lists:

```nix
{
  nitrousOS.software = {
    enable = true;
    core = {
      enable = true;
      packages = with pkgs; [
        wget vim git just vscodium
        htop neofetch           # Add custom packages
      ];
    };
  };
}
```

## Trixie-Specific Options

For Headscale coordination servers:

```nix
{
  nitrousOS.trixie.mode = "full";  # full | relay | exit-node | derp
}
```

| Mode | Components |
|------|------------|
| `full` | Headscale + DERP + Tailscale |
| `relay` | DERP relay only |
| `exit-node` | Tailscale exit node |
| `derp` | DERP server only |

## User Profiles

User profiles define user accounts, credentials, and software selections. They are stored in `oem/user/` and automatically imported into all system configurations.

### User File Structure

Each user file in `oem/user/` can specify which system profiles it should be enabled for:

```nix
# oem/user/myuser.nix
{ config, pkgs, lib, ... }:

let
  enableForSystems = [ "dinitrogen" ];  # Only enable for these systems
  enabled = builtins.elem (config.nitrousOS.system or "") enableForSystems;
in
{
  config = lib.mkIf enabled {
    users.users.myuser = {
      isNormalUser = true;
      description = "My User";
      extraGroups = [ "networkmanager" "wheel" ];
    };

    # Software selections for this user
    nitrousOS.software.enable = true;
    nitrousOS.software.browsers.enable = true;
  };
}
```

### Available Users

| User | Enabled Systems | Description |
|------|-----------------|-------------|
| `justin` | dinitrogen | Desktop user with full software suite |
| `admin` | oxide, trixie | Server admin with SSH key auth |

### Adding a New User

1. Create a new file in `oem/user/`:
   ```bash
   touch oem/user/newuser.nix
   ```

2. Define the user with system conditions:
   ```nix
   { config, pkgs, lib, ... }:
   let
     enableForSystems = [ "dinitrogen" "oxide" ];
     enabled = builtins.elem (config.nitrousOS.system or "") enableForSystems;
   in
   {
     config = lib.mkIf enabled {
       users.users.newuser = {
         isNormalUser = true;
         description = "New User";
         extraGroups = [ "wheel" ];
       };
     };
   }
   ```

3. The user will be automatically imported via `oem/user/default.nix`.

## Creating a Custom Profile

Profiles combine configuration for specific use cases.

### Example: Web Server

```nix
# oem/profiles/webserver/default.nix
{ config, pkgs, ... }:
{
  imports = [ ../oxide ];  # Inherit oxide server base

  # Web server
  services.nginx = {
    enable = true;
    virtualHosts."example.com" = {
      root = "/var/www/example.com";
      enableACME = true;
      forceSSL = true;
    };
  };

  # Database
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "myapp" ];
  };

  # Firewall
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

### Example: Development Workstation

```nix
# oem/profiles/devbox/default.nix
{ config, pkgs, ... }:
{
  imports = [ ../dinitrogen ];  # Inherit full desktop

  # Additional dev tools
  environment.systemPackages = with pkgs; [
    docker
    kubernetes-helm
    terraform
    awscli2
  ];

  # Docker
  virtualisation.docker.enable = true;

  # VS Code with extensions
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      ms-python.python
      rust-lang.rust-analyzer
    ];
  };
}
```

## Adding Hardware Configuration

For physical machines, create a hardware configuration:

```nix
# oem/hardware/my-machine.nix
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules
  boot.initrd.availableKernelModules = [
    "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  # NVIDIA GPU (if applicable)
  hardware.nvidia.prime = {
    offload.enable = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # Firmware
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
}
```

## State Version

**Important**: Do not change `system.stateVersion` unless you understand the implications.

```nix
{
  system.stateVersion = "25.11";  # Current version
}
```

The state version affects:
- Default configuration values
- Database schema migrations
- Service upgrade paths

## Example Complete Configuration

```nix
# flake.nix entry for a custom machine
my-workstation = nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./lib/system
    ./oem/profiles/dinitrogen
    ./oem/hardware/my-hardware.nix
    {
      nitrousOS.system = "dinitrogen";

      # Core
      nitrousOS.core.locale.timeZone = "Europe/London";

      # Plugins
      nitrousOS.plugin.desktop.cosmic.enable = true;
      nitrousOS.plugin.dynamicGpu = {
        enable = true;
        defaultMode = "auto";
      };

      # Software
      nitrousOS.software = {
        enable = true;
        core.enable = true;
        browsers.enable = true;
        dev.enable = true;
      };

      # LUKS
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
