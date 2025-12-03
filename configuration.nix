# configuration.nix
# OEM configuration layer - machine and user specific settings
{ config, pkgs, ... }:

{
  imports = [
    # Hardware configuration (machine-specific)
    ./oem/hardware/hardware-configuration.nix
    ./oem/hardware/nvidia-laptop-lenovo-p14s.nix

    # User profiles
    ./oem/user
  ];

  # LUKS device for this machine
  boot.initrd.luks.devices."luks-f91c7866-4b76-4443-b10f-4a0fe5689f16".device =
    "/dev/disk/by-uuid/f91c7866-4b76-4443-b10f-4a0fe5689f16";

  system.stateVersion = "25.11";
}
