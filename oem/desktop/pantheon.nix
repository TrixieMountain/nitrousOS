{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;
  services.xserver.desktopManager.pantheon.enable = true;

  services.displayManager.lightdm.enable = true;
  services.displayManager.autoLogin.enable = lib.mkDefault false;

  # Pantheon theming
  environment.systemPackages = with pkgs.pantheon; [
    elementary-gtk-theme
    elementary-icon-theme
    granite
  ];
}
