---
title: "Download"
description: "Get nitrousOS source code and pre-built images"
---

## Source Code

The recommended way to use nitrousOS is to clone the repository and build from source.

### Clone Repository

```bash
git clone https://github.com/TrixieMountain/nitrousOS.git
cd nitrousOS
```

### Latest Release

<a href="https://github.com/TrixieMountain/nitrousOS/releases/latest" class="btn btn-primary">Download Latest Release</a>

Available formats:
- Source archive (ZIP)
- Source archive (tar.gz)
- Source archive (7z)

---

## Build Your Own Images

nitrousOS is designed to be built from source. This ensures you get exactly the system you want.

### Quick Test

```bash
# Test in a VM (no system changes)
just sandbox dinitrogen
```

### Build VM Images

```bash
# Build all formats
just build-vms oxide

# Output location
ls dist/vm/oxide/
```

### Build ISO

```bash
just iso dinitrogen
```

---

## Pre-Built Images

Due to GitHub's 2GB file size limit, pre-built VM images are not hosted on GitHub Releases.

To get pre-built images:

1. **Build locally** (recommended):
   ```bash
   git clone https://github.com/TrixieMountain/nitrousOS.git
   cd nitrousOS
   just build-vms oxide
   ```

2. **Community mirrors** - Check the [GitHub Discussions](https://github.com/TrixieMountain/nitrousOS/discussions) for community-hosted mirrors.

---

## System Requirements

### For Building

- Linux system with Nix installed
- ~20GB free disk space for build cache
- ~50GB for building all VM formats

### Minimum VM Requirements

| Target | RAM | Disk | vCPUs |
|--------|-----|------|-------|
| Dinitrogen | 4 GB | 20 GB | 2 |
| Oxide | 1 GB | 10 GB | 1 |
| Trixie | 2 GB | 10 GB | 1 |

### Recommended VM Requirements

| Target | RAM | Disk | vCPUs |
|--------|-----|------|-------|
| Dinitrogen | 8 GB | 50 GB | 4 |
| Oxide | 2 GB | 20 GB | 2 |
| Trixie | 4 GB | 20 GB | 2 |

---

## Verification

All releases include SHA256 checksums:

```bash
sha256sum -c SHA256SUMS
```

---

## Version History

See the [CHANGELOG](https://github.com/TrixieMountain/nitrousOS/blob/master/CHANGELOG.md) for detailed release notes.

### Current Version: 0.2.2

**Recent changes:**
- User profile system - separate users from system profiles
- System-conditional user activation
- Updated documentation

<a href="https://github.com/TrixieMountain/nitrousOS/releases" class="btn btn-secondary">View All Releases</a>
