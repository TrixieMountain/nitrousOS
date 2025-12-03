# lib/plugin/desktop/kde.nix
# KDE Plasma 6 desktop environment
{ config, pkgs, lib, ... }:

{
  options.nitrousOS.plugin.desktop.kde = {
    enable = lib.mkEnableOption "KDE Plasma 6 desktop environment";
  };

  config = lib.mkIf config.nitrousOS.plugin.desktop.kde.enable {
    services.xserver.enable = true;
    services.xserver.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.enable = true;
    services.displayManager.autoLogin.enable = lib.mkDefault false;
  };
}
