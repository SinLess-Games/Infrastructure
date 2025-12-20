#!/usr/bin/env bash
# scripts/initialize-repo.sh

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Bootstrap
# ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# import logging functions
source "$SCRIPT_DIR/logging.sh"

log_info "Initializing repository..."

PACKAGES_FILE="$SCRIPT_DIR/configs/packages.yaml"
BREWFILE="$SCRIPT_DIR/configs/Brewfile"

USER_NAME="$(whoami)"

# Prevent running entire script as root
if [[ "$(id -u)" -eq 0 ]]; then
  log_error "Do not run this script as root. Run it as a normal user with sudo access."
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# Detect OS and Distribution
# ─────────────────────────────────────────────────────────────
detect_os_distro() {
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

  if [[ "$OS" == "linux" ]]; then
    if command -v lsb_release &>/dev/null; then
      DISTRO="$(lsb_release -is | tr '[:upper:]' '[:lower:]')"
    elif [[ -f /etc/os-release ]]; then
      DISTRO="$(. /etc/os-release && echo "$ID" | tr '[:upper:]' '[:lower:]')"
    else
      log_fatal "Unable to determine Linux distribution."
    fi
  else
    DISTRO="$OS"
  fi

  log_info "Detected OS: $OS | Distribution: $DISTRO"
}

# ─────────────────────────────────────────────────────────────
# Check for internet connectivity
# ─────────────────────────────────────────────────────────────
check_internet() {
  if ! ping -c 1 -W 1 1.1.1.1 &>/dev/null; then
    log_fatal "No internet connectivity detected."
  fi
}

# ─────────────────────────────────────────────────────────────
# Offer passwordless sudo (explicit opt-in)
# ─────────────────────────────────────────────────────────────
setup_passwordless_sudo() {
  read -rp "Enable passwordless sudo for ${USER_NAME}? (y/N): " reply
  reply="${reply,,}"

  [[ "$reply" != "y" ]] && {
    log_info "Passwordless sudo skipped."
    return
  }

  if ! sudo -l &>/dev/null; then
    log_fatal "User does not have sudo privileges."
  fi

  log_warn "Configuring passwordless sudo for ${USER_NAME}"

  echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/${USER_NAME}" >/dev/null
  sudo chmod 0440 "/etc/sudoers.d/${USER_NAME}"

  log_info "Passwordless sudo enabled for ${USER_NAME}"
}

# ─────────────────────────────────────────────────────────────
# Ensure Homebrew is installed
# ─────────────────────────────────────────────────────────────
install_homebrew() {
  if command -v brew &>/dev/null; then
    log_info "Homebrew already installed."
    return
  fi

  log_warn "Homebrew not found. Installing..."

  case "$OS" in
    darwin)
      NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      ;;
    linux)
      NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      BREW_SHELLENV='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
      if ! grep -q 'brew shellenv' "$HOME/.bashrc"; then
        echo "$BREW_SHELLENV" >>"$HOME/.bashrc"
      fi
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      ;;
    *)
      log_fatal "Homebrew is not supported on OS: $OS"
      ;;
  esac

  log_info "Homebrew installation completed."
}

# ─────────────────────────────────────────────────────────────
# Install Homebrew packages via Brewfile
# ─────────────────────────────────────────────────────────────
install_brew_packages() {
  if [[ ! -f "$BREWFILE" ]]; then
    log_warn "Brewfile not found, skipping Homebrew packages."
    return
  fi

  log_info "Installing Homebrew packages from Brewfile"
  brew bundle --file="$BREWFILE"
  log_info "Homebrew package installation complete."
}

# ─────────────────────────────────────────────────────────────
# Run task-based setup
# ─────────────────────────────────────────────────────────────
run_tasks() {
  if command -v task &>/dev/null; then
    log_info "Running task ansible:init"
    task ansible:init
  else
    log_warn "go-task not installed, skipping task execution."
  fi
}

# ─────────────────────────────────────────────────────────────
# Execution order
# ─────────────────────────────────────────────────────────────
detect_os_distro
check_internet
setup_passwordless_sudo
install_homebrew
install_brew_packages
run_tasks

log_info "Repository initialization completed successfully."
