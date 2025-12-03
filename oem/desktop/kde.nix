{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;
  services.xserver.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.autoLogin.enable = lib.mkDefault false;
}
