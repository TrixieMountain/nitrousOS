# lib/core/boot.nix
# Bootloader configuration
{ config, lib, pkgs, ... }:

{
  options.nitrousOS.core.boot = {
    enable = lib.mkEnableOption "nitrousOS boot configuration" // { default = true; };
  };

  config = lib.mkIf config.nitrousOS.core.boot.enable {
    boot.loader.systemd-boot.enable = lib.mkDefault true;
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  };
}
