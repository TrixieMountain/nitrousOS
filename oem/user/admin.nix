# oem/user/admin.nix
# User: admin - Server/headless systems
# Only enabled for: oxide, trixie
{ config, pkgs, lib, ... }:

let
  enableForSystems = [ "oxide" "trixie" ];
  enabled = builtins.elem (config.nitrousOS.system or "") enableForSystems;
in
{
  config = lib.mkIf enabled {
    users.users.admin = {
      isNormalUser = true;
      description = "Admin";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        # Add your SSH public keys here
      ];
    };
  };
}
