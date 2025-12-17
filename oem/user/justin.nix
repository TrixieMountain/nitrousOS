# oem/user/justin.nix
# User: justin - Full-featured desktop user
# Only enabled for: dinitrogen
{ config, pkgs, lib, ... }:

let
  enableForSystems = [ "dinitrogen" ];
  enabled = builtins.elem (config.nitrousOS.system or "") enableForSystems;
in
{
  config = lib.mkIf enabled {
    users.users.justin = {
      isNormalUser = true;
      description = "Justin";
      extraGroups = [ "networkmanager" "wheel" "scanner" "lp" ];
    };

    # Auto-login
    services.displayManager.autoLogin.enable = true;
    services.displayManager.autoLogin.user = "justin";

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
  };
}
