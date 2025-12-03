# lib/plugin/desktop/cosmic.nix
# COSMIC desktop environment
{ config, pkgs, lib, ... }:

{
  options.nitrousOS.plugin.desktop.cosmic = {
    enable = lib.mkEnableOption "COSMIC desktop environment";
  };

  config = lib.mkIf config.nitrousOS.plugin.desktop.cosmic.enable {
    services.displayManager.cosmic-greeter.enable = true;
    services.desktopManager.cosmic.enable = true;

    services.system76-scheduler.enable = true;

    programs.firefox.preferences = {
      "widget.gtk.libadwaita-colors.enabled" = false;
    };

    services.displayManager.autoLogin.enable = lib.mkDefault false;
  };
}
