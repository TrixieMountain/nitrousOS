#!/usr/bin/env bash
# This file is both:
#   1) A runnable bash script
#   2) A pure Nix derivation 
#
# On first execution, the bash prelude builds the embedded Nix expression
# into a final self-contained executable, then re-runs itself in --real mode.

if [[ -z "$NIX_BUILD_TOP" && "$1" != "--real" ]]; then
  exec nix-build --no-out-link <(
    sed '1,/^# NIX START$/d' "$0"
  ) --arg real "\"$0\"" \
    && exec "$0" --real "$@"
fi

# NIX START
{ pkgs ? import <nixpkgs> {}, real ? "" }:

pkgs.stdenv.mkDerivation {
  name = "gpu-run-wrapper";
  dontUnpack = true;
  dontBuild  = true;

  installPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/gpu-run <<'EOF'
#!/usr/bin/env bash
# Auto GPU Provider Wrapper
#
# Providers supported:
#   • NVIDIA (proprietary)          – PRIME render offload
#   • AMD Radeon (Mesa)             – DRI_PRIME=1
#   • Intel (Mesa)                  – default + fallback
#   • llvmpipe (CPU rasterizer)     – LIBGL_ALWAYS_SOFTWARE=1
#   • Zink (OpenGL-over-Vulkan)     – MESA_LOADER_DRIVER_OVERRIDE=zink
#
# Detection order:
#   1) NVIDIA
#   2) AMD
#   3) Zink
#   4) llvmpipe
#   5) Intel fallback (default)

set -e

# --- GPU DETECTION --------------------------------------------------------
detect_gpu_provider() {
  # NVIDIA detection
  if command -v nvidia-smi >/dev/null 2>&1; then
    echo nvidia
    return
  fi
  if glxinfo 2>/dev/null | grep -qi "NVIDIA"; then
    echo nvidia
    return
  fi

  # AMD detection
  if glxinfo 2>/dev/null | grep -qi "AMD Radeon"; then
    echo amd
    return
  fi

  # Zink detection (OpenGL over Vulkan)
  if vulkaninfo >/dev/null 2>&1 && \
     glxinfo 2>/dev/null | grep -qi "Zink"; then
    echo zink
    return
  fi

  # llvmpipe detection (Mesa CPU)
  if glxinfo 2>/dev/null | grep -qi "llvmpipe"; then
    echo llvmpipe
    return
  fi

  # Fallback to Intel (safe default)
  echo intel
}

provider=$(detect_gpu_provider)

# --- APPLY ENVIRONMENT ----------------------------------------------------
case "$provider" in
  nvidia)
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    ;;

  amd)
    export DRI_PRIME=1
    ;;

  zink)
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export __VK_LAYER_NV_optimus=ZINK
    ;;

  llvmpipe)
    export LIBGL_ALWAYS_SOFTWARE=1
    export MESA_NO_ERROR=1
    ;;

  intel)
    export DRI_PRIME=0
    ;;
esac

# Optional logging to stderr
echo "gpu-run: using provider → $provider" >&2

# Run the user’s requested program
exec "$@"
EOF

    chmod +x $out/bin/gpu-run
  '';
}
