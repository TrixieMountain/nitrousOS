# nitrousOS Module Reference

Complete reference of all `nitrousOS.*` configuration options.

## Core Modules (`nitrousOS.core.*`)

### Boot (`nitrousOS.core.boot`)
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable boot configuration (systemd-boot, EFI) |

### Locale (`nitrousOS.core.locale`)
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable locale/timezone configuration |

### Audio (`nitrousOS.core.audio`)
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable PipeWire audio system |

### Services (`nitrousOS.core.services`)
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable base services (printing, libinput) |

### Nix (`nitrousOS.core.nix`)
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable Nix configuration (flakes, etc.) |
| `autoUpgrade.enable` | bool | false | Enable automatic system upgrades |
| `autoUpgrade.allowReboot` | bool | false | Allow automatic reboot after upgrade |

---

## System Selection (`nitrousOS.system`)

| Option | Type | Values | Description |
|--------|------|--------|-------------|
| `system` | enum | `"dinitrogen"`, `"oxide"`, `"trixie"` | Select system variant |

---

## Desktop Plugins (`nitrousOS.plugin.desktop.*`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cosmic.enable` | bool | false | COSMIC desktop environment |
| `gnome.enable` | bool | false | GNOME desktop environment |
| `kde.enable` | bool | false | KDE Plasma 6 desktop environment |
| `pantheon.enable` | bool | false | Pantheon desktop environment |

---

## Dynamic GPU (`nitrousOS.plugin.dynamicGpu`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable dynamic GPU control |
| `defaultMode` | enum | `"igpu-only"` | Default GPU mode: `"auto"`, `"igpu-only"`, `"dgpu-forced"` |
| `disableMethod` | enum | `"auto"` | Disable method: `"auto"`, `"pci-remove"`, `"acpi-off"` |

**CLI Usage:**
```bash
gpu-mode auto    # Enable dGPU only when docked/external display
gpu-mode igpu    # Same as auto
gpu-mode dgpu    # Force dGPU always on

nvidia-offload <app>  # Run app with NVIDIA GPU
```

---

## Network (`nitrousOS.plugin.network`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `preset` | enum | `"wifi"` | Network preset: `"minimal"`, `"wifi"`, `"wired"` |

---

## Software (`nitrousOS.software.*`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable software module |
| `core.enable` | bool | false | Core utilities (file managers, editors, etc.) |
| `browsers.enable` | bool | false | Web browsers (Firefox, Chromium) |
| `security.enable` | bool | false | Security tools (KeePassXC, etc.) |
| `communication.enable` | bool | false | Chat/email apps |
| `dev.enable` | bool | false | Development tools |
| `pantheon.enable` | bool | false | Pantheon-specific apps |
| `religious.enable` | bool | false | Religious study tools (SWORD, etc.) |

---

## Pantheon Online Services (`nitrousOS.plugin.pantheon`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `onlineSupport` | bool | false | Enable Pantheon online accounts integration |

---

## Example Configuration

```nix
# oem/profiles/my-profile/default.nix
{ config, pkgs, lib, ... }:
{
  # System variant
  nitrousOS.system = "dinitrogen";

  # Desktop
  nitrousOS.plugin.desktop.cosmic.enable = true;

  # GPU control
  nitrousOS.plugin.dynamicGpu = {
    enable = true;
    defaultMode = "igpu-only";
  };

  # Software
  nitrousOS.software = {
    enable = true;
    core.enable = true;
    browsers.enable = true;
    dev.enable = true;
  };
}
```
