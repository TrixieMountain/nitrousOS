# lib/plugin/desktop/gnome.nix
# GNOME desktop environment
{ config, pkgs, lib, ... }:

{
  options.nitrousOS.plugin.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";
  };

  config = lib.mkIf config.nitrousOS.plugin.desktop.gnome.enable {
    services.xserver.enable = true;
    services.xserver.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;
    services.displayManager.autoLogin.enable = lib.mkDefault false;
  };
}
