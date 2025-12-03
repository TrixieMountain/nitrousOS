{ config, pkgs, lib, ... }:

{
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  services.system76-scheduler.enable = true;

  programs.firefox.preferences = {
    "widget.gtk.libadwaita-colors.enabled" = false;
  };

  services.displayManager.autoLogin.enable = lib.mkDefault false;
}
