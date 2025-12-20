# flake.nix
{
  description = "nitrousOS - Modular NixOS distribution";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};

      # Helper to create a disk image from a NixOS configuration
      makeDiskImage = name: nixosConfig:
        let
          config = nixosConfig.config;
        in
        import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
          inherit pkgs config;
          lib = pkgs.lib;
          diskSize = "auto";
          format = "raw";
          partitionTableType = "efi";
        };

    in {
      nixosConfigurations = {
        #######################################################################
        # VM TARGETS (generic - no hardware config)
        # Use these for disk images, VMs, and cloud deployments
        #######################################################################

        # Dinitrogen - Full-featured desktop
        dinitrogen-vm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./lib/system
            ./oem/profiles/dinitrogen
            ./oem/user
            ({ modulesPath, ... }: {
              imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
              nitrousOS.system = "dinitrogen";
              system.stateVersion = "25.11";
              fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
              boot.loader.grub.device = "/dev/sda";
            })
          ];
        };

        # Oxide - Server base (SSH + Tailscale)
        oxide-vm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./lib/system
            ./oem/profiles/oxide
            ./oem/user
            ({ modulesPath, ... }: {
              imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
              nitrousOS.system = "oxide";
              system.stateVersion = "25.11";
              fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
              boot.loader.grub.device = "/dev/sda";
            })
          ];
        };

        # Trixie - Headscale coordination server AIO
        trixie-vm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./lib/system
            ./oem/profiles/trixie
            ./oem/user
            ({ modulesPath, ... }: {
              imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
              nitrousOS.system = "trixie";
              system.stateVersion = "25.11";
              fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
              boot.loader.grub.device = "/dev/sda";
            })
          ];
        };

        #######################################################################
        # OEM HARDWARE TARGETS
        # Physical machine configurations - add your hardware here
        #######################################################################

        # Example: Justin's Lenovo P14s with NVIDIA
        # To use: sudo nixos-rebuild switch --flake .#justin-p14s
        justin-p14s = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./lib/system
            ./oem/profiles/dinitrogen
            ./oem/user
            ./oem/hardware/hardware-configuration.nix
            ./oem/hardware/nvidia-laptop-lenovo-p14s.nix
            {
              nitrousOS.system = "dinitrogen";
              boot.initrd.luks.devices."luks-f91c7866-4b76-4443-b10f-4a0fe5689f16".device =
                "/dev/disk/by-uuid/f91c7866-4b76-4443-b10f-4a0fe5689f16";
              system.stateVersion = "25.11";
            }
          ];
        };

        #######################################################################
        # ALIASES
        #######################################################################

        # Default targets point to VM versions (hardware-agnostic)
        dinitrogen = self.nixosConfigurations.dinitrogen-vm;
        oxide = self.nixosConfigurations.oxide-vm;
        trixie = self.nixosConfigurations.trixie-vm;

        # Legacy alias
        nitrousOS = self.nixosConfigurations.justin-p14s;
      };

      # Disk images for VM deployment
      packages.${system} = {
        dinitrogen-disk = makeDiskImage "dinitrogen" self.nixosConfigurations.dinitrogen-vm;
        oxide-disk = makeDiskImage "oxide" self.nixosConfigurations.oxide-vm;
        trixie-disk = makeDiskImage "trixie" self.nixosConfigurations.trixie-vm;
      };
    };
}
