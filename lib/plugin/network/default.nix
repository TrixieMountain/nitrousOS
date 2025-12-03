# lib/plugin/network/default.nix
# Network configuration plugins
{ config, lib, pkgs, ... }:

{
  options.nitrousOS.plugin.network = {
    preset = lib.mkOption {
      type = lib.types.enum [ "none" "minimal" "wifi" "wired" ];
      default = "none";
      description = "Network configuration preset";
    };

    wiredInterface = lib.mkOption {
      type = lib.types.str;
      default = "enp0s31f6";
      description = "Wired interface name (for wired preset)";
    };
  };

  config = lib.mkMerge [
    # Minimal preset - just DHCP
    (lib.mkIf (config.nitrousOS.plugin.network.preset == "minimal") {
      networking.useDHCP = true;
    })

    # WiFi preset - NetworkManager with DHCP
    (lib.mkIf (config.nitrousOS.plugin.network.preset == "wifi") {
      networking.networkmanager.enable = true;
      networking.useDHCP = true;
    })

    # Wired preset - specific interface only
    (lib.mkIf (config.nitrousOS.plugin.network.preset == "wired") {
      networking.networkmanager.enable = false;
      networking.useDHCP = false;
      networking.interfaces.${config.nitrousOS.plugin.network.wiredInterface}.useDHCP = true;
    })
  ];
}
