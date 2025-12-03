# lib/system/dinitrogen/default.nix
# Dinitrogen - Full-featured nitrousOS system (current working config)
# This is the flagship desktop installation target
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.nitrousOS.system == "dinitrogen") {
    # Core system components (all enabled by default)
    nitrousOS.core.boot.enable = true;
    nitrousOS.core.locale.enable = true;
    nitrousOS.core.audio.enable = true;
    nitrousOS.core.services.enable = true;
    nitrousOS.core.nix.enable = true;

    # Auto-upgrade enabled for dinitrogen
    nitrousOS.core.nix.autoUpgrade.enable = true;
    nitrousOS.core.nix.autoUpgrade.allowReboot = true;

    # Software module available (OEM enables specific categories)
    # nitrousOS.software.enable is set per-user in OEM

    # Desktop environment available via plugins
    # nitrousOS.plugin.desktop.*.enable is set per-user in OEM

    # Dynamic GPU available
    # nitrousOS.plugin.dynamicGpu.enable is set in OEM hardware
  };
}
