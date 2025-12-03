{ config, pkgs, lib, ... }:

let
  userFiles =
    lib.filter
    (file:
      file != "default.nix"
      && lib.hasSuffix ".nix" file
      && !(lib.hasInfix "template" file)
      && (builtins.readDir ./.).${file} == "regular"
    )
    (builtins.attrNames (builtins.readDir ./.));
in {
  imports = map (file: ./. + "/${file}") userFiles;
}
