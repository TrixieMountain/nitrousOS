# lib/plugin/pantheon-online-services.nix
# Pantheon online services integration (GOA, keyring, geoclue, portal, polkit agents)
{ config, pkgs, lib, ... }:

{
  options.nitrousOS.plugin.pantheon.onlineSupport =
    lib.mkEnableOption "Pantheon online-services integration (GOA, keyring, geoclue, portal, polkit agents)";

  config = lib.mkIf config.nitrousOS.plugin.pantheon.onlineSupport {

    services.gnome.gnome-online-accounts.enable = true;
    services.gnome.gnome-keyring.enable = true;

    security.pam.services = {
      login.enableGnomeKeyring = true;
      gdm.enableGnomeKeyring = true;
      lightdm.enableGnomeKeyring = true;
    };

    services.geoclue2.enable = true;

    security.polkit.enable = true;

    environment.systemPackages = with pkgs.pantheon; [
      pantheon-agent-polkit
      pantheon-agent-geoclue2
      elementary-settings-daemon
      elementary-session-settings
      switchboard
      switchboard-with-plugs
      wingpanel
      wingpanel-with-indicators
      xdg-desktop-portal-pantheon
      granite
      granite7
    ];

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        pkgs.pantheon.xdg-desktop-portal-pantheon
      ];
    };
  };
}
