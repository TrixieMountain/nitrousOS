inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
};

{
  imports = [
    ./home.nix
    ./networking.nix
  ];
}
