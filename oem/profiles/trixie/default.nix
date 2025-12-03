# oem/profiles/trixie/default.nix
# Headscale Coordination Server AIO
# All-in-one: Tailscale client, Headscale server, DERP relay
#
# Modes (configure via nitrousOS.trixie.mode):
#   - "full"       : Headscale + DERP + Tailscale (default)
#   - "relay"      : DERP relay only
#   - "exit-node"  : Tailscale exit node only
#   - "derp"       : DERP server only
{ config, pkgs, lib, ... }:

let
  cfg = config.nitrousOS.trixie or { mode = "full"; };
  mode = cfg.mode or "full";
in
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
    hostName = "trixie";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]
        ++ lib.optionals (mode == "full" || mode == "derp" || mode == "relay") [ 443 80 ]
        ++ lib.optionals (mode == "full") [ 8080 ];  # Headscale gRPC
      allowedUDPPorts = [ config.services.tailscale.port ]
        ++ lib.optionals (mode == "full" || mode == "derp" || mode == "relay") [ 3478 ];  # STUN
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
  # Tailscale client
  ################################
  services.tailscale = {
    enable = true;
    useRoutingFeatures = lib.mkIf (mode == "exit-node") "server";
  };

  ################################
  # Headscale server
  ################################
  services.headscale = lib.mkIf (mode == "full") {
    enable = true;
    address = "0.0.0.0";
    port = 8080;
    settings = {
      server_url = "https://trixie.example.com";  # Configure this
      dns = {
        base_domain = "ts.local";
        magic_dns = true;
        nameservers.global = [ "1.1.1.1" "9.9.9.9" ];
      };
      derp = {
        server = {
          enabled = true;
          region_id = 900;
          region_code = "trixie";
          region_name = "Trixie DERP";
          stun_listen_addr = "0.0.0.0:3478";
        };
      };
    };
  };

  ################################
  # Standalone DERP server (when not using headscale's built-in)
  ################################
  # For relay-only or derp-only modes, you'd configure tailscale's derper here
  # This requires the derper package and custom systemd service

  ################################
  # ACME/SSL for HTTPS
  ################################
  security.acme = lib.mkIf (mode == "full" || mode == "derp" || mode == "relay") {
    acceptTerms = true;
    defaults.email = "admin@example.com";  # Configure this
  };
}
