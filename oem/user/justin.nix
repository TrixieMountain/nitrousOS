# oem/user/justin.nix
# User profile for justin
{ config, pkgs, lib, ... }:

{
  users.users.justin = {
    isNormalUser = true;
    description = "Justin";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  ################################
  # Desktop Environment (COSMIC)
  ################################
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "justin";

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

  ################################
  # Software selections
  ################################
  nitrousOS.software.enable = true;

  nitrousOS.software.core.enable = true;
  nitrousOS.software.browsers.enable = true;
  nitrousOS.software.security.enable = true;
  nitrousOS.software.communication.enable = true;
  nitrousOS.software.dev.enable = true;
  nitrousOS.software.pantheon.enable = true;
}
