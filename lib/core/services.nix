# lib/core/services.nix
# Base system services
{ config, lib, pkgs, ... }:

{
  options.nitrousOS.core.services = {
    enable = lib.mkEnableOption "nitrousOS base services" // { default = true; };

    printing = lib.mkEnableOption "printing support" // { default = true; };
  };

  config = lib.mkIf config.nitrousOS.core.services.enable {
    services.printing.enable = config.nitrousOS.core.services.printing;
    services.libinput.enable = true;
  };
}
