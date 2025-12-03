# lib/system/oxide/default.nix
# Oxide - Minimal server/headless nitrousOS system
# Stripped down for containers, VMs, or headless servers
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.nitrousOS.system == "oxide") {
    # Core system - minimal
    nitrousOS.core.boot.enable = true;
    nitrousOS.core.locale.enable = true;
    nitrousOS.core.nix.enable = true;

    # No audio on servers
    nitrousOS.core.audio.enable = false;

    # Minimal services - no printing
    nitrousOS.core.services.enable = true;
    nitrousOS.core.services.printing = false;

    # No auto-upgrade by default for servers (stability)
    nitrousOS.core.nix.autoUpgrade.enable = lib.mkDefault false;

    # No desktop environment
    # No dynamic GPU
  };
}
