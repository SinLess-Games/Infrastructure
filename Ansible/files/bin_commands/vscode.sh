#!/usr/bin/env bash
# =============================================================================
# vscode.sh
# -----------------------------------------------------------------------------
# Local VS Code installer/updater helper.
#
# Usage:
#   vscode install
#   vscode update
#   vscode status
#   vscode version
#   vscode uninstall
#
# Installs the official Visual Studio Code .deb package using apt so dependency
# handling is clean.
# =============================================================================

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# -----------------------------------------------------------------------------
# Optional logger
# -----------------------------------------------------------------------------

LOGGER_CANDIDATES=(
  "${SCRIPT_DIR}/utils/logger.sh"
  "${SCRIPT_DIR}/../utils/logger.sh"
  "/usr/local/lib/sinless/utils/logger.sh"
  "${HOME}/.local/bin/utils/logger.sh"
)

for logger_file in "${LOGGER_CANDIDATES[@]}"; do
  if [[ -r "${logger_file}" ]]; then
    # shellcheck source=/dev/null
    source "${logger_file}"
    break
  fi
done

if ! declare -F log_info >/dev/null 2>&1; then
  log_info() { printf '[INFO] %s: %s\n' "${SCRIPT_NAME}" "$*"; }
  log_success() { printf '[SUCCESS] %s: %s\n' "${SCRIPT_NAME}" "$*"; }
  log_warn() { printf '[WARN] %s: %s\n' "${SCRIPT_NAME}" "$*" >&2; }
  log_error() { printf '[ERROR] %s: %s\n' "${SCRIPT_NAME}" "$*" >&2; }
  log_fatal() { log_error "$*"; exit 1; }
fi

# -----------------------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------------------

VSCODE_BUILD="${VSCODE_BUILD:-stable}"
VSCODE_OS="${VSCODE_OS:-linux-deb-x64}"
VSCODE_DEB_URL="${VSCODE_DEB_URL:-https://code.visualstudio.com/sha/download?build=${VSCODE_BUILD}&os=${VSCODE_OS}}"
VSCODE_CACHE_DIR="${VSCODE_CACHE_DIR:-${HOME}/.cache/sinless/vscode}"
VSCODE_DEB_PATH="${VSCODE_DEB_PATH:-${VSCODE_CACHE_DIR}/vscode-${VSCODE_BUILD}.deb}"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage:
  vscode <command>

Commands:
  install      Download and install the latest VS Code .deb
  update       Download and install the latest VS Code .deb
  reinstall   Force re-download and install the latest VS Code .deb
  status      Show install status
  version     Show installed VS Code version
  uninstall   Remove VS Code package
  help        Show this help

Environment overrides:
  VSCODE_BUILD=stable
  VSCODE_OS=linux-deb-x64
  VSCODE_DEB_URL=<custom .deb URL>
  VSCODE_CACHE_DIR=${HOME}/.cache/sinless/vscode

Examples:
  vscode install
  vscode update
  vscode reinstall
EOF
}

require_command() {
  local cmd="$1"

  if ! command -v "${cmd}" >/dev/null 2>&1; then
    log_fatal "Required command not found: ${cmd}"
  fi
}

sudo_cmd() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

detect_arch() {
  local arch
  arch="$(dpkg --print-architecture 2>/dev/null || true)"

  case "${arch}" in
    amd64)
      VSCODE_OS="${VSCODE_OS:-linux-deb-x64}"
      ;;
    arm64)
      VSCODE_OS="linux-deb-arm64"
      VSCODE_DEB_URL="${VSCODE_DEB_URL:-https://code.visualstudio.com/sha/download?build=${VSCODE_BUILD}&os=${VSCODE_OS}}"
      ;;
    armhf)
      VSCODE_OS="linux-deb-armhf"
      VSCODE_DEB_URL="${VSCODE_DEB_URL:-https://code.visualstudio.com/sha/download?build=${VSCODE_BUILD}&os=${VSCODE_OS}}"
      ;;
    *)
      log_fatal "Unsupported or unknown Debian architecture: ${arch:-unknown}"
      ;;
  esac
}

ensure_linux_deb_host() {
  if ! command -v apt-get >/dev/null 2>&1; then
    log_fatal "This installer requires a Debian/Ubuntu system with apt-get."
  fi

  if ! command -v dpkg >/dev/null 2>&1; then
    log_fatal "This installer requires dpkg."
  fi
}

download_vscode_deb() {
  local force="${1:-false}"

  mkdir -p "${VSCODE_CACHE_DIR}"

  if [[ "${force}" != "true" && -s "${VSCODE_DEB_PATH}" ]]; then
    log_info "Using cached VS Code package: ${VSCODE_DEB_PATH}"
    return 0
  fi

  require_command curl

  log_info "Downloading VS Code .deb package"
  log_info "URL: ${VSCODE_DEB_URL}"

  rm -f "${VSCODE_DEB_PATH}.tmp"

  curl \
    --fail \
    --location \
    --show-error \
    --progress-bar \
    --output "${VSCODE_DEB_PATH}.tmp" \
    "${VSCODE_DEB_URL}"

  if [[ ! -s "${VSCODE_DEB_PATH}.tmp" ]]; then
    rm -f "${VSCODE_DEB_PATH}.tmp"
    log_fatal "Downloaded VS Code package is empty."
  fi

  mv "${VSCODE_DEB_PATH}.tmp" "${VSCODE_DEB_PATH}"

  log_success "Downloaded: ${VSCODE_DEB_PATH}"
}

install_vscode_deb() {
  ensure_linux_deb_host
  detect_arch

  log_info "Installing VS Code from .deb package"

  sudo_cmd apt-get update
  sudo_cmd apt-get install -y "${VSCODE_DEB_PATH}"

  log_success "VS Code install/update complete"

  if command -v code >/dev/null 2>&1; then
    log_info "Installed version: $(code --version | head -n 1)"
  else
    log_warn "VS Code package installed, but 'code' is not currently in PATH."
  fi
}

install_or_update() {
  local force="${1:-false}"

  ensure_linux_deb_host
  detect_arch
  download_vscode_deb "${force}"
  install_vscode_deb
}

show_status() {
  ensure_linux_deb_host

  if dpkg -s code >/dev/null 2>&1; then
    log_success "VS Code package is installed."
    dpkg -s code | awk -F': ' '/^(Package|Status|Version|Architecture):/ { print $1 ": " $2 }'

    if command -v code >/dev/null 2>&1; then
      printf '\ncode command:\n'
      command -v code
    fi
  else
    log_warn "VS Code package is not installed."
    return 1
  fi
}

show_version() {
  if command -v code >/dev/null 2>&1; then
    code --version
    return 0
  fi

  if dpkg -s code >/dev/null 2>&1; then
    dpkg -s code | awk -F': ' '/^Version:/ { print $2 }'
    return 0
  fi

  log_warn "VS Code is not installed."
  return 1
}

uninstall_vscode() {
  ensure_linux_deb_host

  if ! dpkg -s code >/dev/null 2>&1; then
    log_warn "VS Code is not installed."
    return 0
  fi

  log_warn "Removing VS Code package: code"
  sudo_cmd apt-get remove -y code

  log_success "VS Code removed."
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
  local command="${1:-help}"

  case "${command}" in
    install)
      install_or_update false
      ;;
    update)
      install_or_update true
      ;;
    reinstall)
      install_or_update true
      ;;
    status)
      show_status
      ;;
    version)
      show_version
      ;;
    uninstall|remove)
      uninstall_vscode
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      log_error "Unknown command: ${command}"
      echo
      usage
      exit 2
      ;;
  esac
}

main "$@"
