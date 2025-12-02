# /etc/nixos/flake.nix
{
  description = "nitrousOS";

inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
};

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations = {
      nitrousOS = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./lib/system/nitrousOS/default.nix
        ];
      };
    };
  };
}

