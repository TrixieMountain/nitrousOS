{ config, pkgs, ... }:

{
  imports = [
    ./oem/hardware/hardware-configuration.nix
    ./oem/hardware/nvidia-laptop-lenovo-p14s.nix
    ./oem/hardware/dynamic-gpu.nix

    # All user profiles
    ./oem/user/default.nix

    # Software module
    ./oem/software/user-software.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Auto-upgrade
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  system.autoUpgrade.channel = "https://channels.nixos.org/nixos-25.11";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-f91c7866-4b76-4443-b10f-4a0fe5689f16".device =
    "/dev/disk/by-uuid/f91c7866-4b76-4443-b10f-4a0fe5689f16";

  # Localization
  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Services
  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";
}