# lib/core/nix.nix
# Nix and nixpkgs configuration
{ config, lib, pkgs, ... }:

{
  options.nitrousOS.core.nix = {
    enable = lib.mkEnableOption "nitrousOS nix configuration" // { default = true; };

    allowUnfree = lib.mkEnableOption "allow unfree packages" // { default = true; };

    autoUpgrade = {
      enable = lib.mkEnableOption "automatic system upgrades";
      allowReboot = lib.mkEnableOption "allow automatic reboots for upgrades";
      channel = lib.mkOption {
        type = lib.types.str;
        default = "https://channels.nixos.org/nixos-25.11";
        description = "NixOS channel for auto-upgrades";
      };
    };
  };

  config = lib.mkIf config.nitrousOS.core.nix.enable {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    nixpkgs.config.allowUnfree = config.nitrousOS.core.nix.allowUnfree;

    system.autoUpgrade = lib.mkIf config.nitrousOS.core.nix.autoUpgrade.enable {
      enable = true;
      allowReboot = config.nitrousOS.core.nix.autoUpgrade.allowReboot;
      channel = config.nitrousOS.core.nix.autoUpgrade.channel;
    };
  };
}
