# lib/plugin/dynamic-gpu.nix
# Dynamic hybrid GPU control for NVIDIA/Intel laptops
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nitrousOS.plugin.dynamicGpu;

  stateDir = "/var/lib/dynamic-gpu";
  modeFile = "${stateDir}/mode";

  nvidiaOffloadScript = pkgs.writeShellScriptBin "nvidia-offload" ''
    #!/usr/bin/env bash
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus="NVIDIA_only"
    exec "$@"
  '';

  ##########################################################################
  # dGPU Disable Logic
  ##########################################################################
  gpuDisableScript = pkgs.writeShellScript "gpu-disable-core" ''
    #!/bin/sh
    echo "[dynamic-gpu] Disabling dGPU..."

    METHOD_DEFAULT='${cfg.disableMethod}'
    SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
    PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
    PRODUCT_VERSION=$(cat /sys/class/dmi/id/product_version 2>/dev/null || echo "")

    SYS_INFO="$(printf "%s %s %s" "$SYS_VENDOR" "$PRODUCT_NAME" "$PRODUCT_VERSION")"

    METHOD="$METHOD_DEFAULT"

    if [ "$METHOD" = "auto" ]; then
      if printf "%s" "$SYS_INFO" | grep -qiE "lenovo" &&
         printf "%s" "$SYS_INFO" | grep -qiE "thinkpad|p14s|p1|t14|t15|t16|x1|x13|l14|l15|e14|e15|z13|z16"; then
        echo "[dynamic-gpu] ThinkPad detected → using ACPI _OFF"
        METHOD="acpi-off"
      else
        echo "[dynamic-gpu] Non-ThinkPad → using PCI remove"
        METHOD="pci-remove"
      fi
    fi

    echo "[dynamic-gpu] Disable method: $METHOD"

    # Unload modules
    for m in nvidia_drm nvidia_modeset nvidia_uvm nvidia amdgpu radeon; do
      if lsmod | grep -q "$m"; then
        modprobe -r "$m" 2>/dev/null || true
      fi
    done

    if [ "$METHOD" = "acpi-off" ]; then
      echo "[dynamic-gpu] Applying ACPI power-off..."
      modprobe acpi_call 2>/dev/null || true
      if [ -e /proc/acpi/call ]; then
        for path in \
          '\_SB.PCI0.RP05.PEGP._OFF' \
          '\_SB.PCI0.PEG0.PEGP._OFF' \
          '\_SB.PCI0.GFX0._OFF' \
          '\_SB.PEGP._OFF'; do
          echo "$path" > /proc/acpi/call 2>/dev/null || true
        done
      fi
      exit 0
    fi

    if [ "$METHOD" = "pci-remove" ]; then
      for dev in /sys/bus/pci/devices/*; do
        vendor=$(cat "$dev/vendor" 2>/dev/null || echo "")
        if [ "$vendor" = "0x10de" ] || [ "$vendor" = "0x1002" ]; then
          if [ -e "$dev/driver/unbind" ]; then
            echo "$(basename "$dev")" > "$dev/driver/unbind" 2>/dev/null || true
          fi
          echo 1 > "$dev/remove" 2>/dev/null || true
        fi
      done
      exit 0
    fi
  '';

  ##########################################################################
  # dGPU Enable Logic
  ##########################################################################
  gpuEnableScript = pkgs.writeShellScript "gpu-enable-core" ''
    #!/bin/sh
    echo "[dynamic-gpu] Enabling dGPU..."

    SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
    PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
    PRODUCT_VERSION=$(cat /sys/class/dmi/id/product_version 2>/dev/null || echo "")
    SYS_INFO="$(printf "%s %s %s" "$SYS_VENDOR" "$PRODUCT_NAME" "$PRODUCT_VERSION")"

    if printf "%s" "$SYS_INFO" | grep -qiE "lenovo" &&
       printf "%s" "$SYS_INFO" | grep -qiE "thinkpad|p14s"; then
      modprobe acpi_call 2>/dev/null || true
      if [ -e /proc/acpi/call ]; then
        for path in \
          '\_SB.PCI0.RP05.PEGP._ON' \
          '\_SB.PCI0.PEG0.PEGP._ON' \
          '\_SB.PCI0.GFX0._ON' \
          '\_SB.PEGP._ON'; do
          echo "$path" > /proc/acpi/call 2>/dev/null || true
        done
      fi
    fi

    echo 1 > /sys/bus/pci/rescan 2>/dev/null || true

    modprobe amdgpu 2>/dev/null || true
    modprobe radeon 2>/dev/null || true
    modprobe nvidia 2>/dev/null || true
    modprobe nvidia_modeset 2>/dev/null || true
    modprobe nvidia_uvm 2>/dev/null || true
    modprobe nvidia_drm 2>/dev/null || true
  '';

  ##########################################################################
  # External Display Detect
  ##########################################################################
  externalMonitorDetectScript = pkgs.writeShellScript "dynamic-gpu-detect-external" ''
    for status in /sys/class/drm/*/status; do
      name=$(basename "$(dirname "$status")")
      case "$name" in *eDP*|*LVDS*|*DSI*) continue ;; esac
      if [ "$(cat "$status" 2>/dev/null)" = "connected" ]; then
        echo "external-connected"
        exit 0
      fi
    done
    echo "external-disconnected"
  '';

  ##########################################################################
  # Mode Engine
  ##########################################################################
  dynamicGpuApplyScript = pkgs.writeShellScript "dynamic-gpu-apply" ''
    #!/bin/sh
    MODE=$(cat "${modeFile}" 2>/dev/null || echo "${cfg.defaultMode}")
    echo "[dynamic-gpu] Current mode: $MODE"

    case "$MODE" in
      dgpu-forced)
        ${gpuEnableScript}
        exit 0
        ;;
      igpu-only|auto|*)
        # Both igpu-only and auto modes behave the same:
        # - Enable dGPU only when external display or dock is connected
        # - Otherwise disable dGPU for battery savings
        ;;
    esac

    EXT=$(${externalMonitorDetectScript})
    if [ "$EXT" = "external-connected" ]; then
      echo "[dynamic-gpu] External display detected, enabling dGPU"
      ${gpuEnableScript}
      exit 0
    fi

    # Dock detection via Thunderbolt
    DOCKED=0
    if ls /sys/bus/thunderbolt/devices 1>/dev/null 2>&1; then
      if [ "$(ls /sys/bus/thunderbolt/devices)" != "" ]; then
        DOCKED=1
      fi
    fi

    if [ "$DOCKED" -eq 1 ]; then
      echo "[dynamic-gpu] Dock detected, enabling dGPU"
      ${gpuEnableScript}
      exit 0
    fi

    echo "[dynamic-gpu] No external display/dock, disabling dGPU"
    ${gpuDisableScript}
  '';

  ##########################################################################
  # CLI: gpu-mode
  ##########################################################################
  gpuModeScript = pkgs.writeShellScriptBin "gpu-mode" ''
    if [ $# -ne 1 ]; then
      echo "Usage: gpu-mode [auto|igpu|dgpu]"
      exit 1
    fi

    case "$1" in
      auto) MODE="auto" ;;
      igpu) MODE="igpu-only" ;;
      dgpu) MODE="dgpu-forced" ;;
      *) echo "Invalid mode"; exit 1 ;;
    esac

    mkdir -p "${stateDir}"
    echo "$MODE" > "${modeFile}"

    ${dynamicGpuApplyScript}
  '';

  ##########################################################################
  # udev rules
  ##########################################################################
  dockUdevRules = ''
    SUBSYSTEM=="drm", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start dynamic-gpu-apply.service"
    SUBSYSTEM=="thunderbolt", ACTION=="add", RUN+="${pkgs.systemd}/bin/systemctl start dynamic-gpu-apply.service"
    SUBSYSTEM=="thunderbolt", ACTION=="remove", RUN+="${pkgs.systemd}/bin/systemctl start dynamic-gpu-apply.service"
  '';

in
{
  options.nitrousOS.plugin.dynamicGpu = {
    enable = mkEnableOption "Dynamic hybrid GPU control";
    defaultMode = mkOption {
      type = types.enum [ "auto" "igpu-only" "dgpu-forced" ];
      default = "igpu-only";
      description = "Default GPU mode (igpu-only and auto both enable dGPU only when external display/dock connected)";
    };
    disableMethod = mkOption {
      type = types.enum [ "auto" "pci-remove" "acpi-off" ];
      default = "auto";
      description = "Method to disable discrete GPU";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      nvidiaOffloadScript
      gpuModeScript
    ];

    boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];

    boot.extraModprobeConfig = ''
      options nvidia_drm modeset=0
    '';

    boot.blacklistedKernelModules = [ "nouveau" ];

    hardware.graphics.enable = true;

    services.xserver.videoDrivers = [
      "modesetting"
    ];

    hardware.nvidia = {
      modesetting.enable = mkDefault true;
      prime.offload.enable = mkDefault true;
      prime.offload.enableOffloadCmd = mkDefault true;
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 root root -"
    ];

    services.udev.extraRules = dockUdevRules;

    systemd.services.dynamic-gpu-apply = {
      description = "Dynamic GPU apply";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = dynamicGpuApplyScript;
      };
    };

    systemd.timers.dynamic-gpu-watchdog = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10s";
        OnUnitActiveSec = "10s";
      };
    };

    systemd.services.dynamic-gpu-watchdog = {
      description = "Dynamic GPU watchdog";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = dynamicGpuApplyScript;
      };
    };
  };
}
