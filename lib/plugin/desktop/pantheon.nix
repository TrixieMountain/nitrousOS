# lib/plugin/desktop/pantheon.nix
# Pantheon desktop environment (elementary OS style)
{ config, pkgs, lib, ... }:

{
  options.nitrousOS.plugin.desktop.pantheon = {
    enable = lib.mkEnableOption "Pantheon desktop environment";
  };

  config = lib.mkIf config.nitrousOS.plugin.desktop.pantheon.enable {
    services.xserver.enable = true;
    services.xserver.desktopManager.pantheon.enable = true;

    services.xserver.displayManager.lightdm.enable = true;
    services.displayManager.autoLogin.enable = lib.mkDefault false;

    # Pantheon theming
    environment.systemPackages = with pkgs.pantheon; [
      elementary-gtk-theme
      elementary-icon-theme
      granite
    ];
  };
}
