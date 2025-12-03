# lib/core/default.nix
# Core nitrousOS modules - essential components for a bootable system
{ config, lib, pkgs, ... }:

{
  imports = [
    ./boot.nix
    ./locale.nix
    ./audio.nix
    ./services.nix
    ./nix.nix
  ];
}
