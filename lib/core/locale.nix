# lib/core/locale.nix
# Localization settings
{ config, lib, pkgs, ... }:

{
  options.nitrousOS.core.locale = {
    enable = lib.mkEnableOption "nitrousOS locale configuration" // { default = true; };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "America/New_York";
      description = "System time zone";
    };

    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "Default system locale";
    };
  };

  config = lib.mkIf config.nitrousOS.core.locale.enable {
    time.timeZone = config.nitrousOS.core.locale.timeZone;

    i18n.defaultLocale = config.nitrousOS.core.locale.defaultLocale;
    i18n.extraLocaleSettings = {
      LC_ADDRESS = config.nitrousOS.core.locale.defaultLocale;
      LC_IDENTIFICATION = config.nitrousOS.core.locale.defaultLocale;
      LC_MEASUREMENT = config.nitrousOS.core.locale.defaultLocale;
      LC_MONETARY = config.nitrousOS.core.locale.defaultLocale;
      LC_NAME = config.nitrousOS.core.locale.defaultLocale;
      LC_NUMERIC = config.nitrousOS.core.locale.defaultLocale;
      LC_PAPER = config.nitrousOS.core.locale.defaultLocale;
      LC_TELEPHONE = config.nitrousOS.core.locale.defaultLocale;
      LC_TIME = config.nitrousOS.core.locale.defaultLocale;
    };
  };
}
