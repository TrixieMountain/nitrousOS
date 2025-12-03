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

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  ################################
  # User-specific network settings
  ################################
  networking = {
    hostName = "nitrousOS-experimental";
    networkmanager.enable = true;
  };

  ################################
  # Dynamic GPU (per-user choice)
  ################################
  services.dynamicGpu = {
    enable = true;
    defaultMode = "igpu-only";
  };

  ################################
  # User software selections
  ################################
  nitrousOS.software.enable = true;

  nitrousOS.software.core.enable = true;
  nitrousOS.software.browsers.enable = true;
  nitrousOS.software.security.enable = true;
  nitrousOS.software.communication.enable = true;
  nitrousOS.software.dev.enable = true;
  nitrousOS.software.pantheon.enable = true;
}
