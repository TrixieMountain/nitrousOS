# lib/plugin/desktop/default.nix
# Desktop environment plugins - all consolidated into one file
{ config, lib, pkgs, ... }:

let
  cfg = config.nitrousOS.plugin.desktop;
in
{
  options.nitrousOS.plugin.desktop = {
    cosmic.enable = lib.mkEnableOption "COSMIC desktop environment";
    gnome.enable = lib.mkEnableOption "GNOME desktop environment";
    kde.enable = lib.mkEnableOption "KDE Plasma 6 desktop environment";
    pantheon.enable = lib.mkEnableOption "Pantheon desktop environment";
  };

  config = lib.mkMerge [
    ##########################################################################
    # COSMIC
    ##########################################################################
    (lib.mkIf cfg.cosmic.enable {
      services.displayManager.cosmic-greeter.enable = true;
      services.desktopManager.cosmic.enable = true;
      services.system76-scheduler.enable = true;
      services.displayManager.autoLogin.enable = lib.mkDefault false;

      programs.firefox.preferences = {
        "widget.gtk.libadwaita-colors.enabled" = false;
      };
    })

    ##########################################################################
    # GNOME
    ##########################################################################
    (lib.mkIf cfg.gnome.enable {
      services.xserver.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
      services.displayManager.gdm.enable = true;
      services.displayManager.autoLogin.enable = lib.mkDefault false;
    })

    ##########################################################################
    # KDE Plasma 6
    ##########################################################################
    (lib.mkIf cfg.kde.enable {
      services.xserver.enable = true;
      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm.enable = true;
      services.displayManager.autoLogin.enable = lib.mkDefault false;
    })

    ##########################################################################
    # Pantheon
    ##########################################################################
    (lib.mkIf cfg.pantheon.enable {
      services.xserver.enable = true;
      services.xserver.desktopManager.pantheon.enable = true;
      services.xserver.displayManager.lightdm.enable = true;
      services.displayManager.autoLogin.enable = lib.mkDefault false;

      environment.pathsToLink = [ "/share/applications" ];
      environment.systemPackages = with pkgs.pantheon; [
        elementary-gtk-theme
        elementary-icon-theme
        granite
      ];
    })
  ];
}
