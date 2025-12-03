# lib/plugin/desktop/default.nix
# Desktop environment plugins
{ config, lib, pkgs, ... }:

{
  imports = [
    ./cosmic.nix
    ./gnome.nix
    ./kde.nix
    ./pantheon.nix
  ];
}
