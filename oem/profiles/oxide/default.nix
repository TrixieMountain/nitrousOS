# oem/profiles/oxide/default.nix
# Server base profile - SSH + Tailscale only
# Intended as a building block for custom server configurations
{ config, pkgs, lib, ... }:

{
  ################################
  # System user
  ################################
  users.users.admin = {
    isNormalUser = true;
    description = "Admin";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
    ];
  };

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
