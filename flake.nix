# flake.nix
{
  description = "nitrousOS - Modular NixOS distribution";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

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
        # Dinitrogen - Full-featured desktop system (flagship)
        dinitrogen = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./lib/system
            ./configuration.nix
            { nitrousOS.system = "dinitrogen"; }
          ];
        };

        # Oxide - Minimal server/headless system
        oxide = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./lib/system
            ./configuration.nix
            { nitrousOS.system = "oxide"; }
          ];
        };

        # Trixie - Micro Enclave Controller (headscale/derp/tailscale)
        trixie = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./lib/system
            ./configuration.nix
            { nitrousOS.system = "trixie"; }
          ];
        };

        # Legacy alias for backward compatibility
        nitrousOS = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./lib/system
            ./configuration.nix
            { nitrousOS.system = "dinitrogen"; }
          ];
        };
      };

      # Disk images for VM deployment
      packages.${system} = {
        dinitrogen-disk = makeDiskImage "dinitrogen" self.nixosConfigurations.dinitrogen;
        oxide-disk = makeDiskImage "oxide" self.nixosConfigurations.oxide;
        trixie-disk = makeDiskImage "trixie" self.nixosConfigurations.trixie;
      };
    };
}
