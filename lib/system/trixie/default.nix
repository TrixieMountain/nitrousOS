# lib/system/trixie/default.nix
# Trixie - Lightweight desktop nitrousOS system
# For older hardware or minimal resource usage
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.nitrousOS.system == "trixie") {
    # Core system components
    nitrousOS.core.boot.enable = true;
    nitrousOS.core.locale.enable = true;
    nitrousOS.core.audio.enable = true;
    nitrousOS.core.services.enable = true;
    nitrousOS.core.nix.enable = true;

    # No auto-upgrade by default (manual control)
    nitrousOS.core.nix.autoUpgrade.enable = lib.mkDefault false;

    # Software module available but lighter defaults expected
    # Desktop environment: recommend Pantheon or lightweight WM

    # No dynamic GPU (assume integrated-only)
  };
}
