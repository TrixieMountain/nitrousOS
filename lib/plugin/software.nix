# lib/plugin/software.nix
# Software package management with category-based enable flags
{ config, pkgs, lib, ... }:

let
  cfg = config.nitrousOS.software;

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

  options.nitrousOS.software = {

    enable = lib.mkEnableOption "nitrousOS unified software module";

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
        description = "Core utility packages";
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
        description = "Web browser packages";
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
        description = "Security and privacy packages";
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
        description = "Communication packages";
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
        description = "Development packages";
      };
    };

    pantheon = {
      enable = lib.mkEnableOption "Pantheon + Elementary apps";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = pantheonPackages;
        description = "Pantheon/Elementary packages";
      };
    };

  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages =
         (category cfg.core)
      ++ (category cfg.browsers)
      ++ (category cfg.security)
      ++ (category cfg.communication)
      ++ (category cfg.dev)
      ++ (category cfg.pantheon);

  };
}
