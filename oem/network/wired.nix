{ config, pkgs, ... }:

{
  networking.networkmanager.enable = false;

  networking.useDHCP = false;

  networking.interfaces.enp0s31f6.useDHCP = true; # adjust device name
}
