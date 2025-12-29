# lib/plugin/dynamic-gpu.nix
# Dynamic hybrid GPU control for NVIDIA/Intel laptops
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nitrousOS.plugin.dynamicGpu;

  stateDir = "/var/lib/dynamic-gpu";
  modeFile = "${stateDir}/mode";

  ##########################################################################
  # Common Script (sourced by all others)
  ##########################################################################
  gpuCommonScript = pkgs.writeShellScript "gpu-common" ''
    #!/bin/sh
    export PATH="${pkgs.kmod}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:$PATH"

    # Debug mode: set DYNAMIC_GPU_DEBUG=1 to enable verbose logging
    debug() {
      [ "''${DYNAMIC_GPU_DEBUG:-0}" = "1" ] && echo "[dynamic-gpu:debug] $*" >&2
    }

    log() {
      echo "[dynamic-gpu] $*"
    }

    # System detection
    SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
    PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
    PRODUCT_VERSION=$(cat /sys/class/dmi/id/product_version 2>/dev/null || echo "")
    SYS_INFO="$(printf "%s %s %s" "$SYS_VENDOR" "$PRODUCT_NAME" "$PRODUCT_VERSION")"

    debug "System: $SYS_INFO"

    # ThinkPad models that support ACPI GPU control
    THINKPAD_MODELS="thinkpad|p14s|p1|t14|t15|t16|x1|x13|l14|l15|e14|e15|z13|z16"

    is_thinkpad() {
      printf "%s" "$SYS_INFO" | grep -qiE "lenovo" &&
      printf "%s" "$SYS_INFO" | grep -qiE "$THINKPAD_MODELS"
    }

    # Dock detection (robust check)
    is_docked() {
      [ -d /sys/bus/thunderbolt/devices ] &&
      [ -n "$(ls -A /sys/bus/thunderbolt/devices 2>/dev/null)" ]
    }

    # External display detection
    has_external_display() {
      for status in /sys/class/drm/*/status; do
        name=$(basename "$(dirname "$status")")
        case "$name" in *eDP*|*LVDS*|*DSI*) continue ;; esac
        if [ "$(cat "$status" 2>/dev/null)" = "connected" ]; then
          return 0
        fi
      done
      return 1
    }
  '';

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
    . ${gpuCommonScript}

    log "Disabling dGPU..."

    METHOD_DEFAULT='${cfg.disableMethod}'
    METHOD="$METHOD_DEFAULT"

    if [ "$METHOD" = "auto" ]; then
      if is_thinkpad; then
        debug "ThinkPad detected → using ACPI _OFF"
        METHOD="acpi-off"
      else
        debug "Non-ThinkPad → using PCI remove"
        METHOD="pci-remove"
      fi
    fi

    log "Disable method: $METHOD"

    # Unload modules
    for m in nvidia_drm nvidia_modeset nvidia_uvm nvidia amdgpu radeon; do
      if lsmod | grep -q "$m"; then
        debug "Unloading module: $m"
        modprobe -r "$m" 2>/dev/null || true
      fi
    done

    if [ "$METHOD" = "acpi-off" ]; then
      log "Applying ACPI power-off..."
      modprobe acpi_call 2>/dev/null || true
      if [ -e /proc/acpi/call ]; then
        for path in \
          '\_SB.PCI0.RP05.PEGP._OFF' \
          '\_SB.PCI0.PEG0.PEGP._OFF' \
          '\_SB.PCI0.GFX0._OFF' \
          '\_SB.PEGP._OFF'; do
          debug "Trying ACPI path: $path"
          echo "$path" > /proc/acpi/call 2>/dev/null || true
        done
      fi
      exit 0
    fi

    if [ "$METHOD" = "pci-remove" ]; then
      for dev in /sys/bus/pci/devices/*; do
        vendor=$(cat "$dev/vendor" 2>/dev/null || echo "")
        if [ "$vendor" = "0x10de" ] || [ "$vendor" = "0x1002" ]; then
          debug "Removing PCI device: $(basename "$dev")"
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
    . ${gpuCommonScript}

    log "Enabling dGPU..."

    if is_thinkpad; then
      debug "ThinkPad detected → using ACPI _ON"
      modprobe acpi_call 2>/dev/null || true
      if [ -e /proc/acpi/call ]; then
        for path in \
          '\_SB.PCI0.RP05.PEGP._ON' \
          '\_SB.PCI0.PEG0.PEGP._ON' \
          '\_SB.PCI0.GFX0._ON' \
          '\_SB.PEGP._ON'; do
          debug "Trying ACPI path: $path"
          echo "$path" > /proc/acpi/call 2>/dev/null || true
        done
      fi
    fi

    debug "Rescanning PCI bus..."
    echo 1 > /sys/bus/pci/rescan 2>/dev/null || true

    debug "Loading GPU modules..."
    modprobe amdgpu 2>/dev/null || true
    modprobe radeon 2>/dev/null || true
    modprobe nvidia 2>/dev/null || true
    modprobe nvidia_modeset 2>/dev/null || true
    modprobe nvidia_uvm 2>/dev/null || true
    modprobe nvidia_drm 2>/dev/null || true
  '';

  ##########################################################################
  # Mode Engine
  ##########################################################################
  dynamicGpuApplyScript = pkgs.writeShellScript "dynamic-gpu-apply" ''
    #!/bin/sh
    . ${gpuCommonScript}

    MODE=$(cat "${modeFile}" 2>/dev/null || echo "${cfg.defaultMode}")
    log "Current mode: $MODE"

    case "$MODE" in
      dgpu-forced)
        debug "Mode is dgpu-forced, enabling dGPU"
        ${gpuEnableScript}
        exit 0
        ;;
      igpu-only|auto|*)
        # Both igpu-only and auto modes behave the same:
        # - Enable dGPU only when external display or dock is connected
        # - Otherwise disable dGPU for battery savings
        debug "Mode is $MODE, checking for external display/dock"
        ;;
    esac

    if has_external_display; then
      log "External display detected, enabling dGPU"
      ${gpuEnableScript}
      exit 0
    fi

    if is_docked; then
      log "Dock detected, enabling dGPU"
      ${gpuEnableScript}
      exit 0
    fi

    log "No external display/dock, disabling dGPU"
    ${gpuDisableScript}
  '';

  ##########################################################################
  # CLI: gpu-mode
  ##########################################################################
  gpuModeScript = pkgs.writeShellScriptBin "gpu-mode" ''
    #!/bin/sh
    . ${gpuCommonScript}

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
    log "Set mode to: $MODE"

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

    # Suspend/resume hooks to properly handle dGPU state
    # Disable dGPU before suspend to prevent freeze on resume
    powerManagement.powerDownCommands = ''
      echo "[dynamic-gpu] Pre-suspend: saving mode and disabling dGPU"
      MODE=$(cat "${modeFile}" 2>/dev/null || echo "${cfg.defaultMode}")
      echo "$MODE" > "${stateDir}/mode-pre-suspend"
      ${gpuDisableScript}
    '';

    powerManagement.resumeCommands = ''
      echo "[dynamic-gpu] Post-resume: restoring GPU state"
      sleep 1
      ${dynamicGpuApplyScript}
    '';

    boot.extraModprobeConfig = ''
      options nvidia_drm modeset=0
    '';

    # Enable deep sleep if available, helps with suspend reliability
    boot.kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=0"  # Don't preserve VRAM on suspend (we disable GPU anyway)
    ];

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
