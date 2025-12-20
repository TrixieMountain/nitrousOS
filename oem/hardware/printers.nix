# oem/hardware/printers.nix
# Printer and scanner configuration for Epson ET-2850
{ config, lib, pkgs, ... }:

{
  # Enable CUPS printing service
  services.printing = {
    enable = lib.mkDefault true;
    drivers = [ pkgs.epson-escpr2 ];
  };

  # Enable scanner support (SANE)
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  # Enable network printer/scanner discovery via Avahi/mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Windows share discovery (WS-Discovery)
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
}
