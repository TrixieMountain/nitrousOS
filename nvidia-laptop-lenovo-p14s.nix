{ config, lib, pkgs, ... }:
{
  imports = [
    ./dynamic-gpu.nix
  ];

  # Laptop-specific NVIDIA config (no driver selection here – dynamic GPU handles that)
  hardware.nvidia = {
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.nvidia.prime = {
    sync.enable = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:3:0:0";
  };
}
