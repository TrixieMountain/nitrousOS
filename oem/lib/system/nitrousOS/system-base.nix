{ config, pkgs, ... }:

let
  # List of GNOME packages to retain
  gnomePackages = [
    pkgs.gnome-backgrounds      # GNOME backgrounds
    pkgs.gnome-bluetooth        # Bluetooth manager
    pkgs.gnome-color-manager    # Color management
    pkgs.gnome-control-center   # Settings panel
    pkgs.gnome-shell-extensions # Shell extensions
    pkgs.gnome-themes-extra     # Extra themes
    pkgs.gnome-user-docs        # Documentation
    pkgs.orca                   # Screen reader
    pkgs.glib                   # Required for gsettings
    pkgs.gnome-menus            # GNOME menu system
    pkgs.gtk3.out               # GTK launcher utility
    pkgs.xdg-user-dirs          # User directories management
    pkgs.gnome-text-editor      # GNOME text editor
    pkgs.loupe                  # Image viewer (optional)
    pkgs.nautilus               # File manager (needed for file access)
    pkgs.snapshot               # Snapshot tool
    pkgs.gnome-console          # The only GNOME package retained
  ];
in

{

  # Import the hardware configuration file
  imports =
    [ ../../../oem/hardware-configuration.nix ];

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
  networking.hostName = "nixos";
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

  # GNOME Desktop Environment configuration
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Exclude unnecessary GNOME packages to reduce bloat
  environment.gnome.excludePackages = [
    pkgs.baobab           # Disk usage analyzer
    pkgs.cheese           # Photo booth
    pkgs.eog              # Image viewer
    pkgs.epiphany         # Web browser
    pkgs.gedit            # Text editor
    pkgs.simple-scan      # Document scanner
    pkgs.totem            # Video player
    pkgs.yelp             # Help viewer
    pkgs.evince           # Document viewer
    pkgs.file-roller      # Archive manager
    pkgs.geary            # Email client
    pkgs.seahorse         # Password manager
    pkgs.gnome-calculator # Calculator
    pkgs.gnome-calendar   # Calendar
    pkgs.gnome-characters # Emoji & symbols
    pkgs.gnome-clocks     # Clocks
    pkgs.gnome-contacts   # Contacts
    pkgs.gnome-font-viewer # Font viewer
    pkgs.gnome-logs       # Logs
    pkgs.gnome-maps       # Maps
    pkgs.gnome-music      # Music
    pkgs.gnome-photos     # Photos
    pkgs.gnome-screenshot # Screenshot tool
    pkgs.gnome-system-monitor # System monitor
    pkgs.gnome-weather    # Weather
    pkgs.gnome-disk-utility # Disk utility
    pkgs.gnome-connections # Remote desktop
    pkgs.gnome-tour        # First-time setup guide
  ];

  # Combine both lists of system packages (gnomePackages + default packages)
  environment.systemPackages = with pkgs; [
    # Add default system packages
    vim                  # Text editor
    wget                 # Download utility
    hardinfo2            # System information tool
    # Add GNOME packages
    pkgs.gnome-backgrounds
    pkgs.gnome-bluetooth
    pkgs.gnome-color-manager
    pkgs.gnome-control-center
    pkgs.gnome-shell-extensions
    pkgs.gnome-themes-extra
    pkgs.gnome-tour
    pkgs.gnome-user-docs
    pkgs.orca
    pkgs.glib
    pkgs.gnome-menus
    pkgs.gtk3.out
    pkgs.xdg-user-dirs
    pkgs.gnome-text-editor
    pkgs.loupe
    pkgs.nautilus
    pkgs.snapshot
    pkgs.gnome-console
  ];

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

  # Enable automatic login for user 'justin'
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "justin";

  # Workaround for GNOME autologin
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Define state version
  system.stateVersion = "25.11";

}
