# lib/helpers/default.nix
# Shared helper functions for nitrousOS modules
{ lib, pkgs, ... }:

{
  ##############################################################################
  # Shell Script Helpers
  ##############################################################################

  # Create a shell script with proper PATH and logging utilities
  # Usage: mkShellScript { name = "my-script"; deps = [ pkgs.coreutils ]; script = "..."; }
  mkShellScript = { name, deps ? [], script }:
    pkgs.writeShellScript name ''
      #!/bin/sh
      export PATH="${lib.makeBinPath deps}:$PATH"

      log() { echo "[${name}] $*"; }
      debug() { [ "''${DEBUG:-0}" = "1" ] && echo "[${name}:debug] $*" >&2; }

      ${script}
    '';

  # Create an executable script (goes in PATH) with proper deps and logging
  mkShellScriptBin = { name, deps ? [], script }:
    pkgs.writeShellScriptBin name ''
      #!/bin/sh
      export PATH="${lib.makeBinPath deps}:$PATH"

      log() { echo "[${name}] $*"; }
      debug() { [ "''${DEBUG:-0}" = "1" ] && echo "[${name}:debug] $*" >&2; }

      ${script}
    '';

  ##############################################################################
  # System-Conditional Helpers
  ##############################################################################

  # Check if the current system is in the given list
  # Usage: lib.mkIf (helpers.isSystem config [ "dinitrogen" ]) { ... }
  isSystem = config: systems:
    builtins.elem (config.nitrousOS.system or "") systems;

  # Create a config block that only applies to specific systems
  # Usage: helpers.mkSystemConfig config [ "dinitrogen" ] { users.users.foo = ...; }
  mkSystemConfig = config: systems: attrs:
    lib.mkIf (builtins.elem (config.nitrousOS.system or "") systems) attrs;
}
