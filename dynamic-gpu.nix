{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dynamicGpu;

  stateDir  = "/var/lib/dynamic-gpu";
  modeFile  = "${stateDir}/mode";
  flagFile  = "${stateDir}/aggressive";

  ##########################################################################
  # Detect dGPU: any non-Intel PCI display controller (NVIDIA / AMD)
  ##########################################################################
  detectDGpu = pkgs.writeShellScript "dynamic-gpu-detect-dgpu" ''
    #!/bin/sh
    # Returns "on" if a non-Intel display controller is present and bound
    for dev in /sys/bus/pci/devices/*; do
      class=$(cat "$dev/class" 2>/dev/null || echo "")
      vendor=$(cat "$dev/vendor" 2>/dev/null || echo "")
      driver=$(basename "$(readlink -f "$dev/driver" 2>/dev/null)" 2>/dev/null || echo "")

      case "$class" in
        0x030000|0x030200|0x038000)
          # treat non-Intel as potential dGPU
          if [ "$vendor" != "0x8086" ] && [ -n "$driver" ]; then
            echo "on"
            exit 0
          fi
          ;;
      esac
    done

    echo "off"
  '';

  ##########################################################################
  # Detect external display: any non-eDP/LVDS/DSI connected output
  ##########################################################################
  detectExternal = pkgs.writeShellScript "dynamic-gpu-detect-external" ''
    #!/bin/sh
    # Returns "external-connected" if any external output is connected.
    for status in /sys/class/drm/*/status; do
      name=$(basename "$(dirname "$status")")
      case "$name" in
        *eDP*|*LVDS*|*DSI*) continue ;;
      esac

      if [ "$(cat "$status" 2>/dev/null)" = "connected" ]; then
        echo "external-connected"
        exit 0
      fi
    done

    echo "external-disconnected"
  '';

  ##########################################################################
  # Runtime dGPU disable (safe, vendor-agnostic)
  ##########################################################################
  runtimeDisable = pkgs.writeShellScript "dynamic-gpu-runtime-disable" ''
    #!/bin/sh
    echo "[dynamic-gpu] Runtime disabling dGPU…"

    # Unload common dGPU modules
    for m in nvidia_drm nvidia_modeset nvidia_uvm nvidia amdgpu radeon; do
      if lsmod | grep -q "^$m "; then
        echo "[dynamic-gpu] Unloading $m"
        modprobe -r "$m" 2>/dev/null || true
      fi
    done

    # Allow runtime PM / D3cold on non-Intel display controllers
    for dev in /sys/bus/pci/devices/*; do
      class=$(cat "$dev/class" 2>/dev/null || echo "")
      vendor=$(cat "$dev/vendor" 2>/dev/null || echo "")

      case "$class" in
        0x030000|0x030200|0x038000)
          if [ "$vendor" != "0x8086" ]; then
            echo "[dynamic-gpu] Enabling runtime PM on $dev"
            echo auto > "$dev/power/control" 2>/dev/null || true
            echo 1    > "$dev/d3cold_allowed" 2>/dev/null || true
          fi
          ;;
      esac
    done

    exit 0
  '';

  ##########################################################################
  # Apply mode semantics:
  #   performance  → leave dGPU alone (assume static config handles it)
  #   balanced     → auto policy based on external monitor, optional aggressive
  #   battery      → always runtime disable dGPU
  #   bios         → do nothing, follow firmware
  ##########################################################################
  applyMode = pkgs.writeShellScript "dynamic-gpu-apply" ''
    #!/bin/sh
    MODE=$(cat ${modeFile} 2>/dev/null || echo "${cfg.defaultMode}")
    AGG="false"
    [ -e ${flagFile} ] && AGG="true"

    DGPU="$(${detectDGpu})"
    EXT="$(${detectExternal})"

    echo "[dynamic-gpu] Mode=$MODE dGPU=$DGPU external=$EXT aggressive=$AGG"

    case "$MODE" in
      battery)
        echo "[dynamic-gpu] battery → forcing iGPU-only via runtime disable."
        ${runtimeDisable}
        ;;

      performance)
        echo "[dynamic-gpu] performance → leaving dGPU state untouched."
        # Your static NixOS config (hardware.nvidia / amdgpu) controls usage.
        ;;

      balanced)
        if [ "$AGG" = "true" ]; then
          if [ "$EXT" = "external-disconnected" ]; then
            echo "[dynamic-gpu] balanced+aggressive → no external, disabling dGPU."
            ${runtimeDisable}
          else
            echo "[dynamic-gpu] balanced+aggressive → external present, leaving dGPU as-is."
          fi
        else
          echo "[dynamic-gpu] balanced → conservative, leaving dGPU state as-is."
          # You can still use static config / tools to turn dGPU on when needed.
        fi
        ;;

      bios)
        echo "[dynamic-gpu] bios → not touching GPU, following firmware."
        ;;

      *)
        echo "[dynamic-gpu] Unknown mode '$MODE', falling back to '${cfg.defaultMode}'."
        echo "${cfg.defaultMode}" > ${modeFile}
        ;;
    esac
  '';

  ##########################################################################
  # gpu-mode CLI
  ##########################################################################
  gpuModeCLI = pkgs.writeShellScriptBin "gpu-mode" ''
    #!/bin/sh

    if [ $# -lt 1 ]; then
      echo "Usage: gpu-mode [performance|balanced|battery|bios] [--aggressive]"
      exit 1
    fi

    MODE="$1"
    AGG="false"
    shift

    while [ $# -gt 0 ]; do
      case "$1" in
        --aggressive) AGG="true" ;;
        *)
          echo "Unknown flag: $1"
          echo "Usage: gpu-mode [performance|balanced|battery|bios] [--aggressive]"
          exit 1
          ;;
      esac
      shift
    done

    case "$MODE" in
      performance|balanced|battery|bios)
        ;;
      *)
        echo "Invalid mode: $MODE"
        echo "Valid modes: performance, balanced, battery, bios"
        exit 1
        ;;
    esac

    mkdir -p ${stateDir}
    echo "$MODE" > ${modeFile}

    if [ "$AGG" = "true" ]; then
      touch ${flagFile}
    else
      rm -f ${flagFile} 2>/dev/null || true
    fi

    ${applyMode}
  '';

in
{
  options.services.dynamicGpu = {
    enable = mkEnableOption "Dynamic GPU simple 3-mode controller";

    defaultMode = mkOption {
      type = types.enum [ "performance" "balanced" "battery" "bios" ];
      default = "balanced";
      description = ''
        Default GPU mode if no state file exists.

        Modes:
        - performance : leave dGPU enabled/available; static config controls usage
        - balanced    : auto policy; with --aggressive can disable dGPU when no external
        - battery     : force iGPU-only by disabling dGPU at runtime
        - bios        : do nothing; firmware/BIOS control GPU fully
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      gpuModeCLI
    ];

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 root root -"
    ];

    # Periodic watcher to re-apply policy (e.g. after plug/unplug)
    systemd.services.dynamic-gpu-apply = {
      description = "Dynamic GPU policy apply";
      serviceConfig = {
        Type      = "oneshot";
        ExecStart = applyMode;
      };
    };

    systemd.timers.dynamic-gpu-apply = {
      description = "Dynamic GPU policy timer";
      wantedBy    = [ "timers.target" ];
      timerConfig = {
        OnBootSec       = "15s";
        OnUnitActiveSec = "15s";
      };
    };
  };
}
