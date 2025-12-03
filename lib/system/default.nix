# lib/system/default.nix
# System variant selector
# Import this and then select a system via nitrousOS.system attribute
{ config, lib, pkgs, ... }:

{
  imports = [
    ../core
    ../plugin
    ./dinitrogen
    ./oxide
    ./trixie
  ];

  options.nitrousOS.system = lib.mkOption {
    type = lib.types.enum [ "dinitrogen" "oxide" "trixie" ];
    default = "dinitrogen";
    description = "nitrousOS system variant to use";
  };
}
