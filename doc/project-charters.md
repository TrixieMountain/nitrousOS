# nitrousOS Project Charters

## Dynamic GPU Plugin (`lib/plugin/dynamic-gpu.nix`)

### Purpose
Automatic hybrid GPU management for laptops with NVIDIA/Intel or AMD/Intel configurations. Enables power saving by disabling the discrete GPU when not needed, and automatically enables it when docking or connecting external displays.

### Features
- Automatic dGPU enable/disable based on dock and external display detection
- ThinkPad-specific ACPI power control for proper GPU power gating
- Three modes: `auto`, `igpu-only`, `dgpu-forced`
- Suspend/resume handling to prevent system crashes
- Debug mode via `DYNAMIC_GPU_DEBUG=1` environment variable

### Usage
```bash
# Set GPU mode
gpu-mode auto    # Enable dGPU only when docked/external display
gpu-mode igpu    # Same as auto (iGPU preferred)
gpu-mode dgpu    # Force dGPU always on

# Run with NVIDIA offloading
nvidia-offload <application>

# Enable debug logging
DYNAMIC_GPU_DEBUG=1 gpu-mode dgpu
```

### Configuration Options
```nix
nitrousOS.plugin.dynamicGpu = {
  enable = true;
  defaultMode = "igpu-only";  # auto | igpu-only | dgpu-forced
  disableMethod = "auto";     # auto | pci-remove | acpi-off
};
```

### Architecture
- `gpuCommonScript` - Shared helper with PATH, logging, and detection functions
- `gpuDisableScript` - Unloads modules, applies ACPI _OFF or PCI remove
- `gpuEnableScript` - Applies ACPI _ON, rescans PCI, loads modules
- `dynamicGpuApplyScript` - Main logic, checks mode and hardware state
- `gpuModeScript` - CLI interface (`gpu-mode` command)

### Suspend/Resume
- Pre-suspend: Saves current mode, disables dGPU
- Post-resume: Waits 1s, restores GPU state based on mode

### Supported Hardware
- ThinkPad models: P14s, P1, T14, T15, T16, X1, X13, L14, L15, E14, E15, Z13, Z16
- Other laptops: Uses PCI remove method (less power efficient but more compatible)
