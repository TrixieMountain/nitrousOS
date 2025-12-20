# lib/core/audio.nix
# Audio subsystem configuration (PipeWire)
{ config, lib, pkgs, ... }:

{
  options.nitrousOS.core.audio = {
    enable = lib.mkEnableOption "nitrousOS audio configuration" // { default = true; };
  };

  config = lib.mkIf config.nitrousOS.core.audio.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
