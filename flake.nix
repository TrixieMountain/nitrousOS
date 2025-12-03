# flake.nix
{
  description = "nitrousOS - Modular NixOS distribution";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      # Dinitrogen - Full-featured desktop system (flagship)
      dinitrogen = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./lib/system
          ./configuration.nix
          { nitrousOS.system = "dinitrogen"; }
        ];
      };

      # Oxide - Minimal server/headless system
      oxide = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./lib/system
          ./configuration.nix
          { nitrousOS.system = "oxide"; }
        ];
      };

      # Trixie - Lightweight desktop system
      trixie = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./lib/system
          ./configuration.nix
          { nitrousOS.system = "trixie"; }
        ];
      };

      # Legacy alias for backward compatibility
      nitrousOS-experimental = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./lib/system
          ./configuration.nix
          { nitrousOS.system = "dinitrogen"; }
        ];
      };
    };
  };
}
