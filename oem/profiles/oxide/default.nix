# oem/profiles/oxide/default.nix
# Server base profile - SSH + Tailscale only
# Intended as a building block for custom server configurations
# User definitions are in oem/user/admin.nix
{ config, pkgs, lib, ... }:

{
  ################################
  # Network settings
  ################################
  networking = {
    hostName = "oxide";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };

  ################################
  # SSH
  ################################
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  ################################
  # Tailscale
  ################################
  services.tailscale.enable = true;
}
