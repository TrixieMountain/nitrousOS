{ config, pkgs, ... }:

{

  # Import the hardware configuration file
  imports =
    [ 
      ./hardware-configuration.nix 
      ./nvidia-laptop-lenovo-p14s.nix
    ];

  # Enable experimental features for Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System Auto-Upgrade
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  system.autoUpgrade.channel = "https://channels.nixos.org/nixos-25.11";

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-f91c7866-4b76-4443-b10f-4a0fe5689f16".device = "/dev/disk/by-uuid/f91c7866-4b76-4443-b10f-4a0fe5689f16";

  # Network and Hostname setup
  networking.hostName = "nitrousOS-experimental";
  networking.networkmanager.enable = true;

  # Time zone and locale settings
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

  # START COSMIC COSMIC DESKTOP ENVIRONMENT CONFIGURATION
  # Enable the COSMIC login manager
  services.displayManager.cosmic-greeter.enable = true;
  # Enable the COSMIC desktop environment
  services.desktopManager.cosmic.enable = true;
  # Software package exclusions
  environment.cosmic.excludePackages = with pkgs; [
    # cosmic-edit
  ];
  # Use system76 scheduler for COSMIC speed improvements
  services.system76-scheduler.enable = true;
  # Disable forced Firefox theming
  programs.firefox.preferences = {
    # disable libadwaita theming for Firefox
    "widget.gtk.libadwaita-colors.enabled" = false;
  };
  # END COSMIC DESKTOP ENVIRONMENT CONFIGURATION

  # CUPS printing service
  services.printing.enable = true;

  # Pipewire audio configuration
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support
  services.libinput.enable = true;

  # User setup for 'justin'
  users.users.justin = {
    isNormalUser = true;
    description = "justin";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      thunderbird
      firefox
      chromium
      mullvad
      mullvad-browser
      keepassxc
      tailscale
      clamav
      vscodium
      git
      just
      claude-code
      vim
      wget
      hardinfo2
    ];
  };

  services.dynamicGpu = {
    enable = true;
    defaultMode = "battery";
  };

# Enable automatic login for user 'justin'
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "justin";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Define state version
  system.stateVersion = "25.11";

}
