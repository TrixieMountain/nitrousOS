---
title: "Documentation"
description: "Complete guide to installing, configuring, and using nitrousOS"
---

Welcome to the nitrousOS documentation. Here you'll find everything you need to get started with nitrousOS, from quick installation to advanced configuration.

## Quick Links

- [Getting Started](/docs/getting-started/) - First steps with nitrousOS
- [Installation](/docs/installation/) - Install on physical hardware
- [Configuration](/docs/configuration/) - System and plugin configuration
- [Targets](/docs/targets/) - System variants explained
- [VM Builder](/docs/vm-builder/) - Build VM images for any platform

## System Variants

nitrousOS offers three specialized system variants:

| Variant | Use Case | Desktop | Services |
|---------|----------|---------|----------|
| **Dinitrogen** | Full-featured desktop | COSMIC | All plugins available |
| **Oxide** | Minimal server | None | SSH + Tailscale |
| **Trixie** | Network infrastructure | None | Headscale + DERP |

## Architecture Overview

nitrousOS uses a layered architecture:

```
┌─────────────────────────────────────────────────────┐
│  OEM Layer (oem/)                                   │
│  └─ Hardware configs, user profiles                 │
├─────────────────────────────────────────────────────┤
│  System Variants (lib/system/)                      │
│  └─ Dinitrogen, Oxide, Trixie                       │
├─────────────────────────────────────────────────────┤
│  Plugin Layer (lib/plugin/)                         │
│  └─ Desktop, GPU, software, networking              │
├─────────────────────────────────────────────────────┤
│  Core Layer (lib/core/)                             │
│  └─ Boot, locale, audio, services, nix              │
├─────────────────────────────────────────────────────┤
│  NixOS Base                                         │
└─────────────────────────────────────────────────────┘
```
