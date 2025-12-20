# oem/profiles/dinitrogen/default.nix
# Full-featured desktop profile - system configuration
# User definitions are in oem/user/justin.nix
{ config, pkgs, lib, cosmicOverlay, ... }:

{
  ################################
  # Desktop Environment (COSMIC 1.0)
  ################################
  nixpkgs.overlays = [ cosmicOverlay ];
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
