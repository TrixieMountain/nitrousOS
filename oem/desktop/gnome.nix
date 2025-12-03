{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = lib.mkDefault false;
}
