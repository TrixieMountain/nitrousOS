# oem/profiles/dinitrogen/default.nix
# Full-featured desktop profile - system configuration
# User definitions are in oem/user/justin.nix
{ config, pkgs, lib, ... }:

{
  ################################
  # Desktop Environment (COSMIC)
  ################################
  nitrousOS.plugin.desktop.cosmic.enable = true;

  ################################
  # Network settings
  ################################
  networking = {
    hostName = "nitrousOS";
    networkmanager.enable = true;
  };

  ################################
  # Dynamic GPU
  ################################
  nitrousOS.plugin.dynamicGpu = {
    enable = true;
    defaultMode = "igpu-only";
  };
}
