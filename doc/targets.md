# Targets

nitrousOS provides multiple system targets for different use cases.

## Target Types

### VM Targets (Generic)

These targets have no hardware-specific configuration and are suitable for:
- QEMU/KVM virtual machines
- Cloud deployments (AWS, Azure, GCP)
- Container/VM platforms (Proxmox, VMware, VirtualBox)

| Target | Description |
|--------|-------------|
| `dinitrogen-vm` | Full desktop environment |
| `oxide-vm` | Minimal server base |
| `trixie-vm` | Headscale coordination server |

### OEM Hardware Targets

These targets include machine-specific hardware configuration:

| Target | Description |
|--------|-------------|
| `justin-p14s` | Lenovo P14s with NVIDIA GPU |

Add your own hardware targets in the `OEM HARDWARE TARGETS` section of `flake.nix`.

### Aliases

For convenience, short names are aliased to VM targets:

| Alias | Points To |
|-------|-----------|
| `dinitrogen` | `dinitrogen-vm` |
| `oxide` | `oxide-vm` |
| `trixie` | `trixie-vm` |
| `nitrousOS` | `justin-p14s` (legacy) |

---

## Dinitrogen

**Full-featured desktop system**

### Features
- Configurable desktop environment (choose one):
  - **COSMIC** - Modern Rust-based DE from System76
  - **Pantheon** - Elegant elementary OS-style DE
  - **GNOME** - Popular GTK-based DE
  - **KDE Plasma** - Feature-rich Qt-based DE
- NetworkManager for connectivity
- Dynamic GPU switching (NVIDIA/Intel)
- Full software suite:
  - Browsers
  - Security tools
  - Communication apps
  - Development tools
  - Pantheon utilities

### Use Cases
- Daily driver workstation
- Development machine
- Creative workstation

### Profile Location
- System: `oem/profiles/dinitrogen/default.nix`
- User: `oem/user/justin.nix`

### Switching Desktop Environment

Edit `oem/profiles/dinitrogen/default.nix` and enable your preferred DE:

```nix
# Choose ONE of the following:
nitrousOS.plugin.desktop.cosmic.enable = true;    # COSMIC (default)
nitrousOS.plugin.desktop.pantheon.enable = true;  # Pantheon
nitrousOS.plugin.desktop.gnome.enable = true;     # GNOME
nitrousOS.plugin.desktop.kde.enable = true;       # KDE Plasma
```

---

## Oxide

**Minimal server base**

### Features
- SSH server (key-based auth only)
- Tailscale for secure networking
- Minimal footprint
- No GUI

### Use Cases
- Building block for custom servers
- Docker/container host
- Database server
- Web server base

### Profile Location
- System: `oem/profiles/oxide/default.nix`
- User: `oem/user/admin.nix`

### Customization

Oxide is intentionally minimal. Extend it by creating a new profile:

```nix
# oem/profiles/my-server/default.nix
{ config, pkgs, ... }:
{
  imports = [ ../oxide ];  # Inherit oxide base

  # Add your services
  services.nginx.enable = true;
  services.postgresql.enable = true;
}
```

---

## Trixie

**Headscale Coordination Server AIO**

An all-in-one solution for running your own Tailscale control plane.

### Features
- **Headscale** - Self-hosted Tailscale control server
- **DERP** - Built-in relay server
- **Tailscale** - Client for mesh connectivity
- SSH server for management
- ACME/Let's Encrypt support

### Modes

Configure via `nitrousOS.trixie.mode`:

| Mode | Components |
|------|------------|
| `full` (default) | Headscale + DERP + Tailscale |
| `relay` | DERP relay only |
| `exit-node` | Tailscale exit node only |
| `derp` | DERP server only |

### Use Cases
- Self-hosted Tailscale control plane
- Private mesh network coordinator
- VPN exit node
- DERP relay for improved connectivity

### Profile Location
- System: `oem/profiles/trixie/default.nix`
- User: `oem/user/admin.nix`

### Configuration

After deployment, configure Headscale:

```bash
# Create a user
headscale users create myuser

# Generate auth key
headscale authkeys create --user myuser

# On clients, connect with:
tailscale up --login-server https://your-trixie-server:8080 --authkey <key>
```

---

## Adding Custom Targets

### New VM Target

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
      nitrousOS.system = "oxide";  # or appropriate variant
      system.stateVersion = "25.11";
      fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
      boot.loader.grub.device = "/dev/sda";
    })
  ];
};
```

### New Hardware Target

Add to `flake.nix` in the OEM HARDWARE TARGETS section:

```nix
my-machine = nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./lib/system
    ./oem/profiles/dinitrogen  # or your profile
    ./oem/user
    ./oem/hardware/my-hardware-configuration.nix
    {
      nitrousOS.system = "dinitrogen";
      # LUKS devices, etc.
      system.stateVersion = "25.11";
    }
  ];
};
```
