# nitrousOS Architecture

nitrousOS is a modular NixOS distribution designed for flexibility and maintainability. This document explains the directory structure and how modules interact.

## Directory Structure

```
nitrousOS/
├── flake.nix              # Entry point - defines all system targets
├── justfile               # Build commands (just build, just vm, etc.)
├── lib/                   # Core modules (system-agnostic)
│   ├── core/              # Essential system components
│   ├── helpers/           # Shared Nix functions
│   ├── plugin/            # Optional features
│   ├── system/            # System variant definitions
│   └── install/           # Installation scripts
├── oem/                   # Machine-specific customizations
│   ├── profiles/          # System profiles (what services run)
│   ├── user/              # User account definitions
│   └── hardware/          # Hardware-specific configs
├── doc/                   # Documentation
└── resources/             # Scripts and assets
```

## Module Hierarchy

```
flake.nix
    │
    ├── lib/system/default.nix (imports core + plugins)
    │       ├── lib/core/* (boot, audio, locale, services, nix)
    │       ├── lib/plugin/* (desktop, software, dynamic-gpu, etc.)
    │       └── lib/system/{variant}/ (dinitrogen, oxide, trixie)
    │
    ├── oem/profiles/{variant}/ (system-specific settings)
    ├── oem/user/ (user accounts)
    └── oem/hardware/ (hardware configs - only for physical machines)
```

## Key Concepts

### System Variants
Three predefined system types:

| Variant | Purpose | Features |
|---------|---------|----------|
| **dinitrogen** | Desktop | Audio, auto-upgrade, desktop environments |
| **oxide** | Server | SSH, Tailscale, minimal footprint |
| **trixie** | Coordination | Headscale server, DERP relay |

Select with: `nitrousOS.system = "dinitrogen";`

### lib/ vs oem/
- **lib/** contains reusable, hardware-agnostic modules
- **oem/** contains machine-specific customizations
- lib/ should NEVER import from oem/ (separation of concerns)

### Plugins
Optional features enabled via `nitrousOS.plugin.*`:

```nix
nitrousOS.plugin.desktop.cosmic.enable = true;
nitrousOS.plugin.dynamicGpu.enable = true;
nitrousOS.software.browsers.enable = true;
```

### Helpers Library
`lib/helpers/default.nix` provides shared functions:

```nix
helpers = import ./lib/helpers { inherit lib pkgs; };

# Create scripts with proper PATH
helpers.mkShellScript { name = "my-script"; deps = [ pkgs.curl ]; script = "..."; }

# Check current system variant
lib.mkIf (helpers.isSystem config [ "dinitrogen" ]) { ... }
```

## Adding a New Plugin

1. Create `lib/plugin/my-plugin.nix`:
```nix
{ config, lib, pkgs, ... }:
{
  options.nitrousOS.plugin.myPlugin = {
    enable = lib.mkEnableOption "My Plugin";
  };

  config = lib.mkIf config.nitrousOS.plugin.myPlugin.enable {
    # Your configuration here
  };
}
```

2. Import in `lib/plugin/default.nix`
3. Enable in your profile: `nitrousOS.plugin.myPlugin.enable = true;`

## Adding a New Hardware Target

1. Generate hardware config: `nixos-generate-config --show-hardware-config > oem/hardware/my-machine.nix`
2. Add to `flake.nix`:
```nix
my-machine = nixpkgs.lib.nixosSystem {
  modules = [
    ./lib/system
    ./oem/profiles/dinitrogen  # or your preferred variant
    ./oem/user
    ./oem/hardware/my-machine.nix
    { nitrousOS.system = "dinitrogen"; system.stateVersion = "25.11"; }
  ];
};
```
3. Build: `sudo nixos-rebuild switch --flake .#my-machine`

## Debugging

Enable debug mode for dynamic-gpu and other scripts:
```bash
DEBUG=1 gpu-mode dgpu
DYNAMIC_GPU_DEBUG=1 gpu-mode auto
```

Check journal logs:
```bash
journalctl -u dynamic-gpu-apply.service -f
journalctl -u dynamic-gpu-watchdog.service -f
```
