# lib/plugin/default.nix
# Plugin modules - optional features and extensions
{ config, lib, pkgs, ... }:

{
  imports = [
    ./software.nix
    ./dynamic-gpu.nix
    ./desktop/default.nix
    ./network/default.nix
    ./pantheon-online-services.nix
  ];
}
