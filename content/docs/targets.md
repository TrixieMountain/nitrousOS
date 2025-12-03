---
title: "System Targets"
description: "Detailed guide to nitrousOS system variants"
weight: 4
---

nitrousOS provides three specialized system variants, each optimized for different use cases.

## Target Types

### VM Targets (Generic)

Hardware-agnostic targets for virtualization and cloud:

| Target | Description |
|--------|-------------|
| `dinitrogen-vm` | Full desktop environment |
| `oxide-vm` | Minimal server base |
| `trixie-vm` | Headscale coordination server |

### OEM Hardware Targets

Machine-specific targets with hardware configuration:

| Target | Description |
|--------|-------------|
| `justin-p14s` | Lenovo P14s with NVIDIA GPU |

### Aliases

Short names that point to VM targets:

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

- **COSMIC desktop environment** - Modern, responsive DE from System76
- **NetworkManager** - Flexible network configuration
- **Dynamic GPU switching** - NVIDIA/Intel hybrid graphics
- **Complete software suite**:
  - Browsers (Firefox, Chromium, Mullvad Browser)
  - Security tools (KeePassXC, Mullvad VPN, ClamAV)
  - Communication (Signal, Thunderbird)
  - Development tools
  - Pantheon utilities

### Use Cases

- Daily driver workstation
- Development machine
- Creative workstation
- General desktop computing

### Configuration

System profile: `oem/profiles/dinitrogen/default.nix`
User profile: `oem/user/justin.nix`

```nix
# oem/profiles/dinitrogen/default.nix
{
  nitrousOS.plugin.desktop.cosmic.enable = true;

  networking = {
    hostName = "nitrousOS";
    networkmanager.enable = true;
  };

  nitrousOS.plugin.dynamicGpu = {
    enable = true;
    defaultMode = "igpu-only";
  };
}
```

---

## Oxide

**Minimal server base**

### Features

- **SSH server** - Key-based authentication only
- **Tailscale** - Mesh networking for secure access
- **Minimal footprint** - No GUI, no audio, no printing
- **Firewall** - Enabled with SSH and Tailscale ports open

### Use Cases

- Docker/container host
- Database server
- Web server base
- Kubernetes node
- Building block for custom servers

### Configuration

System profile: `oem/profiles/oxide/default.nix`
User profile: `oem/user/admin.nix`

```nix
# oem/profiles/oxide/default.nix
{
  networking = {
    hostName = "oxide";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.tailscale.enable = true;
}
```

### Extending Oxide

Create a custom profile that inherits from Oxide:

```nix
# oem/profiles/my-server/default.nix
{ config, pkgs, ... }:
{
  imports = [ ../oxide ];

  # Add your services
  services.nginx.enable = true;
  services.postgresql.enable = true;

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

---

## Trixie

**Headscale Coordination Server (AIO)**

An all-in-one solution for self-hosted Tailscale control plane.

### Features

- **Headscale** - Self-hosted Tailscale control server
- **Built-in DERP** - Relay server for improved connectivity
- **Tailscale client** - For mesh connectivity
- **SSH server** - For management
- **ACME/Let's Encrypt** - HTTPS certificate automation

### Operation Modes

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

### Configuration

System profile: `oem/profiles/trixie/default.nix`
User profile: `oem/user/admin.nix`

```nix
# oem/profiles/trixie/default.nix
{
  networking = {
    hostName = "trixie";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 443 80 8080 ];
      allowedUDPPorts = [ config.services.tailscale.port 3478 ];
    };
  };

  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 8080;
    settings = {
      server_url = "https://trixie.example.com";
      dns = {
        base_domain = "ts.local";
        magic_dns = true;
        nameservers.global = [ "1.1.1.1" "9.9.9.9" ];
      };
      derp.server = {
        enabled = true;
        region_id = 900;
        region_code = "trixie";
        stun_listen_addr = "0.0.0.0:3478";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };
}
```

### Setup After Deployment

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
      nitrousOS.system = "oxide";
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
    ./oem/profiles/dinitrogen
    ./oem/user
    ./oem/hardware/my-hardware.nix
    {
      nitrousOS.system = "dinitrogen";
      boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/...";
      system.stateVersion = "25.11";
    }
  ];
};
```
