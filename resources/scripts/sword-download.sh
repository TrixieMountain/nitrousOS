#!/usr/bin/env bash
# SWORD Module Downloader
# Downloads Bible modules from CrossWire and other SWORD repositories
#
# Usage:
#   ./sword-download.sh [--all | --bibles | --list | --source <name>]
#
# Options:
#   --all         Download all modules (Bibles, commentaries, dictionaries, etc.) ~660MB
#   --bibles      Download only Bible texts
#   --list        List available modules without downloading
#   --source      Specify source (default: CrossWire)
#                 Available: CrossWire, "CrossWire Beta", eBible.org, "STEP Bible", etc.
#   --help        Show this help message

set -euo pipefail

# Ensure common tools are in PATH
export PATH="/run/current-system/sw/bin:$PATH"

SWORD_PATH="${SWORD_PATH:-$HOME/.sword}"
SOURCE="${SOURCE:-CrossWire}"
MODE="bibles"
INSTALLMGR_FLAGS="--allow-internet-access-and-risk-tracing-and-jail-or-martyrdom"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    head -20 "$0" | tail -18 | sed 's/^# //' | sed 's/^#//'
    exit 0
}

check_deps() {
    if ! command -v installmgr &>/dev/null; then
        log_error "installmgr not found. Install sword package first."
        log_info "Run: nix-shell -p sword"
        exit 1
    fi
}

init_sword() {
    mkdir -p "$SWORD_PATH/mods.d"

    if [[ ! -f "$SWORD_PATH/InstallMgr/InstallMgr.conf" ]]; then
        log_info "Initializing SWORD configuration..."
        echo -e "yes\nyes" | installmgr -init
    fi

    log_info "Syncing remote source list..."
    installmgr $INSTALLMGR_FLAGS -sc
}

list_sources() {
    log_info "Available remote sources:"
    installmgr $INSTALLMGR_FLAGS -s
}

refresh_source() {
    local source="$1"
    log_info "Refreshing source: $source"
    installmgr $INSTALLMGR_FLAGS -r "$source"
}

list_modules() {
    local source="$1"
    refresh_source "$source"
    log_info "Available modules from $source:"
    installmgr $INSTALLMGR_FLAGS -rl "$source"
}

get_module_list() {
    local source="$1"
    installmgr $INSTALLMGR_FLAGS -rl "$source" 2>/dev/null | \
        grep -E '^\*\[' | \
        sed 's/.*\[\([^]]*\)\].*/\1/'
}

# Filter for Bible texts only (heuristic based on common naming patterns)
filter_bibles() {
    grep -iE '^(KJV|ASV|ESV|NIV|NASB|RSV|NRSV|NLT|MSG|AMP|CEV|GNT|NET|WEB|YLT|DBY|Darby|BBE|AKJV|Geneva|DRC|Vulg|LXX|Septuagint|MT|BHS|WLC|OSHB|TR|Byz|NA|UBS|Tisch|Aleph|Aleppo|Leningrad|Chi|Cze|Dut|Fin|Fre|Ger|Gre|Heb|Hun|Ita|Jpn|Kor|Lat|Nor|Pol|Por|Rom|Rus|Spa|Swe|Ukr|Vie|Ara|Afr|Alb|Arm|Bel|Bul|Bur|Cop|Cro|Dan|Est|Far|Geo|Hin|Ice|Ind|Kaz|Lit|Mac|Mal|Mao|Mon|Nep|Per|Ser|Slk|Slv|Som|Swa|Tgl|Tha|Tur|Uzb|BSB|CPDV|Common|AB|ABP|ACV|AFV|EMTV|ISV|Jubilee|LITV|MKJV|RV|Webster|Bishops|Wycliffe|Tyndale|Coverdale|Matthew|Great|Taverner|.*Bible.*|.*Testament.*|.*Scripture.*)'
}

download_module() {
    local source="$1"
    local module="$2"

    if installmgr $INSTALLMGR_FLAGS -ri "$source" "$module" 2>&1; then
        log_success "Installed: $module"
        return 0
    else
        log_warn "Failed to install: $module"
        return 1
    fi
}

download_all() {
    local source="$1"
    local modules

    refresh_source "$source"
    modules=$(get_module_list "$source")

    local total=$(echo "$modules" | wc -l)
    local count=0
    local failed=0

    log_info "Downloading all $total modules from $source..."
    log_warn "Estimated size: ~660MB (compressed)"
    echo

    while IFS= read -r module; do
        ((count++)) || true
        echo -ne "\r[${count}/${total}] Installing: ${module}                    "
        if ! download_module "$source" "$module" &>/dev/null; then
            ((failed++)) || true
        fi
    done <<< "$modules"

    echo
    log_success "Completed: $((total - failed)) succeeded, $failed failed"
}

download_bibles() {
    local source="$1"
    local modules

    refresh_source "$source"
    modules=$(get_module_list "$source" | filter_bibles || true)

    if [[ -z "$modules" ]]; then
        log_warn "No Bible modules matched filter. Downloading common ones..."
        modules="KJV ASV ESV NASB RSV WEB BBE Darby Geneva DRC LXX Byz BSB"
    fi

    local total=$(echo "$modules" | wc -w)
    local count=0
    local failed=0

    log_info "Downloading Bible modules from $source..."
    echo

    for module in $modules; do
        ((count++)) || true
        echo -ne "\r[${count}/${total}] Installing: ${module}                    "
        if ! download_module "$source" "$module" &>/dev/null; then
            ((failed++)) || true
        fi
    done

    echo
    log_success "Completed: $((total - failed)) succeeded, $failed failed"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            MODE="all"
            shift
            ;;
        --bibles)
            MODE="bibles"
            shift
            ;;
        --list)
            MODE="list"
            shift
            ;;
        --sources)
            MODE="sources"
            shift
            ;;
        --source)
            SOURCE="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            ;;
    esac
done

# Main
check_deps
init_sword

case $MODE in
    sources)
        list_sources
        ;;
    list)
        list_modules "$SOURCE"
        ;;
    all)
        download_all "$SOURCE"
        ;;
    bibles)
        download_bibles "$SOURCE"
        ;;
esac

log_info "SWORD modules installed to: $SWORD_PATH"
