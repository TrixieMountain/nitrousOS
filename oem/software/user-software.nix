{ config, pkgs, lib, ... }:

let
  # Packages that should NOT be auto-included in Pantheon app discovery
  pantheonSkip = [
    "elementary-screenshot-tool"   # deprecated alias
    "elementary-feedback"          # removed upstream
    "elementary-print-shim"        # transitional / deprecated
  ];

  # Discover all Pantheon / Elementary apps (safe version)
  pantheonApps =
    builtins.filter
      (name:
        builtins.match "elementary-.*" name != null
        && !(builtins.elem name pantheonSkip)
      )
      (builtins.attrNames pkgs.pantheon);

  pantheonPackages =
    map (app: pkgs.pantheon.${app}) pantheonApps;

  # Safe list logic — avoids mkIf set/list conflicts
  category = attrs: lib.optionals attrs.enable attrs.packages;

in {

  ##########################################################################
  # Options definition
  ##########################################################################
  options.nitrousOS.software = {

    enable = lib.mkEnableOption "NitrousOS unified software module";

    core = {
      enable = lib.mkEnableOption "Core utilities";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          wget
          vim
          git
          just
          vscodium
        ];
      };
    };

    browsers = {
      enable = lib.mkEnableOption "Web browsers";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          firefox
          chromium
          mullvad-browser
        ];
      };
    };

    security = {
      enable = lib.mkEnableOption "Security + privacy tools";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          keepassxc
          mullvad
          clamav
          tailscale
        ];
      };
    };

    communication = {
      enable = lib.mkEnableOption "Communication tools";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          signal-desktop
          thunderbird
        ];
      };
    };

    dev = {
      enable = lib.mkEnableOption "Development tools";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          claude-code
          hardinfo2
        ];
      };
    };

    pantheon = {
      enable = lib.mkEnableOption "Pantheon + Elementary apps";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = pantheonPackages;
      };
    };

  };

  ##########################################################################
  # Config implementation
  ##########################################################################
  config = lib.mkIf config.nitrousOS.software.enable {

    environment.systemPackages =
         (category config.nitrousOS.software.core)
      ++ (category config.nitrousOS.software.browsers)
      ++ (category config.nitrousOS.software.security)
      ++ (category config.nitrousOS.software.communication)
      ++ (category config.nitrousOS.software.dev)
      ++ (category config.nitrousOS.software.pantheon);

  };
}
