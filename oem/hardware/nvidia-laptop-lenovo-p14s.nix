# oem/hardware/nvidia-laptop-lenovo-p14s.nix
# Lenovo ThinkPad P14s NVIDIA hardware configuration
{ config, lib, pkgs, ... }:

{
  # Laptop-specific NVIDIA config
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
