#!/usr/bin/env bash
# =============================================================================
# Repository Initialization
# -----------------------------------------------------------------------------
# Purpose:
#   Bootstraps local development tooling for the Infrastructure repository.
#
# What it does:
#   - Detects OS/distribution
#   - Refuses root execution
#   - Verifies internet access
#   - Verifies sudo access when needed
#   - Installs baseline OS packages from scripts/configs/packages.yaml when
#     supported
#   - Installs Homebrew when missing
#   - Installs packages from scripts/configs/Brewfile
#   - Initializes Ansible tooling through go-task when available
#   - Falls back to direct Ansible virtualenv + Galaxy initialization when task
#     is unavailable
#
# Usage:
#   ./scripts/initialize-repo.sh
#
# Optional environment flags:
#   NONINTERACTIVE=1             Avoid prompts
#   DEBUG=1                      Enable debug logging
#
#   SKIP_OS_PACKAGES=1           Skip baseline OS package installation
#   SKIP_BREW=1                  Skip Homebrew installation and Brewfile packages
#   SKIP_BREW_BUNDLE=1           Skip brew bundle only
#   SKIP_TASKS=1                 Skip go-task execution
#   SKIP_ANSIBLE_INIT=1          Skip direct Ansible fallback initialization
#
#   ENABLE_PASSWORDLESS_SUDO=1   Configure passwordless sudo without prompting
#
#   FORCE_OS_PACKAGES=1          Reinstall/refresh OS packages even when basic
#                               commands already exist
# =============================================================================

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PACKAGES_FILE="$SCRIPT_DIR/configs/packages.yaml"
BREWFILE="$SCRIPT_DIR/configs/Brewfile"

ANSIBLE_DIR="$REPO_ROOT/Ansible"
ANSIBLE_VENV="$ANSIBLE_DIR/.venv"
ANSIBLE_REQUIREMENTS_TXT="$ANSIBLE_DIR/requirements.txt"
ANSIBLE_REQUIREMENTS_YAML="$ANSIBLE_DIR/requirements.yaml"
ANSIBLE_COLLECTIONS_DIR="$ANSIBLE_DIR/.collections"
ANSIBLE_ROLES_DIR="$ANSIBLE_COLLECTIONS_DIR/roles"

# shellcheck source=scripts/logging.sh
source "$SCRIPT_DIR/logging.sh"

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------

OS=""
DISTRO=""
DISTRO_VERSION=""
USER_NAME="$(id -un)"

# -----------------------------------------------------------------------------
# Error handling
# -----------------------------------------------------------------------------

on_error() {
  local exit_code=$?
  local line_no=${1:-unknown}

  log_error "Repository initialization failed at line ${line_no} with exit code ${exit_code}."
  exit "$exit_code"
}

trap 'on_error "$LINENO"' ERR

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_truthy() {
  case "${1:-}" in
    1 | true | TRUE | yes | YES | y | Y | on | ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

require_not_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    log_fatal "Do not run this script as root. Run it as a normal user with sudo access."
  fi
}

detect_os_distro() {
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

  case "$OS" in
    linux)
      if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO="${ID,,}"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
      elif command_exists lsb_release; then
        DISTRO="$(lsb_release -is | tr '[:upper:]' '[:lower:]')"
        DISTRO_VERSION="$(lsb_release -rs)"
      else
        log_fatal "Unable to determine Linux distribution."
      fi
      ;;
    darwin)
      DISTRO="macos"
      DISTRO_VERSION="$(sw_vers -productVersion 2>/dev/null || echo unknown)"
      ;;
    *)
      DISTRO="$OS"
      DISTRO_VERSION="unknown"
      ;;
  esac

  log_info "Detected OS: ${OS} | Distribution: ${DISTRO} | Version: ${DISTRO_VERSION}"
}

check_internet() {
  log_info "Checking internet connectivity."

  if command_exists curl; then
    curl -fsSL --connect-timeout 5 https://github.com >/dev/null
    log_success "Internet connectivity verified."
    return
  fi

  if command_exists wget; then
    wget -q --spider --timeout=5 https://github.com
    log_success "Internet connectivity verified."
    return
  fi

  if command_exists ping; then
    ping -c 1 -W 2 1.1.1.1 >/dev/null
    log_success "Internet connectivity verified."
    return
  fi

  if command_exists timeout; then
    timeout 5 bash -c 'cat < /dev/null > /dev/tcp/github.com/443' >/dev/null 2>&1
    log_success "Internet connectivity verified."
    return
  fi

  log_fatal "Unable to check internet connectivity because curl, wget, ping, and timeout are unavailable."
}

require_sudo() {
  if [[ "$OS" != "linux" && "$OS" != "darwin" ]]; then
    return
  fi

  if ! command_exists sudo; then
    log_fatal "sudo is required but was not found."
  fi

  log_info "Checking sudo access."
  sudo -v
  log_success "Sudo access verified."
}

setup_passwordless_sudo() {
  local enable="false"

  if is_truthy "${ENABLE_PASSWORDLESS_SUDO:-0}"; then
    enable="true"
  elif is_truthy "${NONINTERACTIVE:-0}"; then
    log_info "Passwordless sudo skipped in non-interactive mode."
    return
  else
    local reply
    read -r -p "Enable passwordless sudo for ${USER_NAME}? (y/N): " reply

    case "${reply,,}" in
      y | yes)
        enable="true"
        ;;
      *)
        log_info "Passwordless sudo skipped."
        return
        ;;
    esac
  fi

  if [[ "$enable" != "true" ]]; then
    return
  fi

  require_sudo

  log_warn "Configuring passwordless sudo for ${USER_NAME}."

  printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$USER_NAME" \
    | sudo tee "/etc/sudoers.d/${USER_NAME}" >/dev/null

  sudo chmod 0440 "/etc/sudoers.d/${USER_NAME}"
  sudo visudo -cf "/etc/sudoers.d/${USER_NAME}" >/dev/null

  log_success "Passwordless sudo enabled for ${USER_NAME}."
}

parse_debian_packages_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  awk '
    BEGIN { in_packages = 0 }

    /^[[:space:]]*packages:[[:space:]]*$/ {
      in_packages = 1
      next
    }

    in_packages == 1 && /^[^[:space:]-]/ {
      exit
    }

    in_packages == 1 && /^[[:space:]]*-[[:space:]]*/ {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      sub(/[[:space:]]+#.*/, "", line)
      gsub(/["'\''"]/, "", line)
      gsub(/[[:space:]]+$/, "", line)

      if (line != "") {
        print line
      }
    }

    # Backward compatibility for the old flat list format:
    # - git
    # - curl
    in_packages == 0 && /^[[:space:]]*-[[:space:]]*/ {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      sub(/[[:space:]]+#.*/, "", line)
      gsub(/["'\''"]/, "", line)
      gsub(/[[:space:]]+$/, "", line)

      if (line != "") {
        print line
      }
    }
  ' "$file"
}

install_os_packages_apt() {
  local packages=("$@")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    packages=(
      build-essential
      gcc
      g++
      make
      pkg-config
      git
      curl
      wget
      ca-certificates
      gnupg
      lsb-release
      dnsutils
      iproute2
      iputils-ping
      net-tools
      jq
      unzip
      tar
      python3
      python3-venv
      python3-pip
      python3-apt
      sudo
      software-properties-common
    )
  fi

  log_info "Installing baseline OS packages with apt."
  require_sudo

  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"

  log_success "Baseline OS packages installed."
}

install_os_packages_dnf() {
  log_info "Installing baseline OS packages with dnf."
  require_sudo

  sudo dnf groupinstall -y "Development Tools"
  sudo dnf install -y \
    procps-ng \
    curl \
    wget \
    file \
    git \
    ca-certificates \
    bind-utils \
    iproute \
    iputils \
    jq \
    unzip \
    tar \
    python3 \
    python3-pip \
    sudo

  log_success "Baseline OS packages installed."
}

install_os_packages_pacman() {
  log_info "Installing baseline OS packages with pacman."
  require_sudo

  sudo pacman -Sy --needed --noconfirm \
    base-devel \
    procps-ng \
    curl \
    wget \
    file \
    git \
    ca-certificates \
    bind \
    iproute2 \
    iputils \
    jq \
    unzip \
    tar \
    python \
    python-pip \
    sudo

  log_success "Baseline OS packages installed."
}

install_os_packages() {
  if is_truthy "${SKIP_OS_PACKAGES:-0}"; then
    log_info "Baseline OS package installation skipped."
    return
  fi

  if [[ "$OS" != "linux" ]]; then
    log_info "Baseline OS package installation skipped for ${OS}."
    return
  fi

  if ! is_truthy "${FORCE_OS_PACKAGES:-0}" \
    && command_exists git \
    && command_exists curl \
    && command_exists python3; then
    log_success "Baseline OS packages appear to already be installed."
    return
  fi

  case "$DISTRO" in
    ubuntu | debian | linuxmint | pop)
      mapfile -t debian_packages < <(parse_debian_packages_file "$PACKAGES_FILE" || true)
      install_os_packages_apt "${debian_packages[@]}"
      ;;
    fedora)
      install_os_packages_dnf
      ;;
    arch | manjaro)
      install_os_packages_pacman
      ;;
    *)
      log_warn "No automatic baseline package installer for distro: ${DISTRO}"
      log_warn "Install build tools, curl, git, Python 3, pip, jq, and DNS tools manually if bootstrap fails."
      ;;
  esac
}

load_homebrew_shellenv() {
  if command_exists brew; then
    return
  fi

  local brew_bin=""

  case "$OS" in
    darwin)
      if [[ -x /opt/homebrew/bin/brew ]]; then
        brew_bin="/opt/homebrew/bin/brew"
      elif [[ -x /usr/local/bin/brew ]]; then
        brew_bin="/usr/local/bin/brew"
      fi
      ;;
    linux)
      if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        brew_bin="/home/linuxbrew/.linuxbrew/bin/brew"
      fi
      ;;
  esac

  if [[ -n "$brew_bin" ]]; then
    eval "$("$brew_bin" shellenv)"
  fi
}

persist_homebrew_shellenv() {
  local shellenv_line=""
  local profile_file="$HOME/.profile"

  case "$OS" in
    darwin)
      if [[ -x /opt/homebrew/bin/brew ]]; then
        shellenv_line='eval "$(/opt/homebrew/bin/brew shellenv)"'
      elif [[ -x /usr/local/bin/brew ]]; then
        shellenv_line='eval "$(/usr/local/bin/brew shellenv)"'
      fi
      ;;
    linux)
      shellenv_line='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
      ;;
  esac

  if [[ -z "$shellenv_line" ]]; then
    return
  fi

  if [[ -n "${SHELL:-}" && "$SHELL" == */zsh ]]; then
    profile_file="$HOME/.zprofile"
  elif [[ -f "$HOME/.bashrc" ]]; then
    profile_file="$HOME/.bashrc"
  fi

  touch "$profile_file"

  if ! grep -Fq "$shellenv_line" "$profile_file"; then
    printf '\n# Homebrew\n%s\n' "$shellenv_line" >>"$profile_file"
    log_info "Added Homebrew shellenv to ${profile_file}."
  fi
}

install_homebrew() {
  if is_truthy "${SKIP_BREW:-0}"; then
    log_info "Homebrew installation skipped."
    return
  fi

  load_homebrew_shellenv

  if command_exists brew; then
    log_success "Homebrew already installed: $(brew --version | head -n 1)"
    return
  fi

  if ! command_exists curl; then
    log_fatal "curl is required to install Homebrew."
  fi

  log_warn "Homebrew not found. Installing."

  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  load_homebrew_shellenv
  persist_homebrew_shellenv

  if ! command_exists brew; then
    log_fatal "Homebrew installation completed, but brew is still not available in PATH."
  fi

  log_success "Homebrew installed: $(brew --version | head -n 1)"
}

install_brew_packages() {
  if is_truthy "${SKIP_BREW:-0}" || is_truthy "${SKIP_BREW_BUNDLE:-0}"; then
    log_info "Brewfile package installation skipped."
    return
  fi

  if [[ ! -f "$BREWFILE" ]]; then
    log_warn "Brewfile not found at ${BREWFILE}; skipping Homebrew packages."
    return
  fi

  if ! command_exists brew; then
    log_fatal "brew is required for Brewfile installation but was not found."
  fi

  log_info "Installing Homebrew packages from ${BREWFILE}."

  if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
    log_success "Homebrew packages already satisfy Brewfile."
    return
  fi

  brew bundle --file="$BREWFILE"

  log_success "Homebrew package installation complete."
}

python_bin() {
  if command_exists python3; then
    command -v python3
    return
  fi

  if command_exists python; then
    command -v python
    return
  fi

  return 1
}

initialize_ansible_direct() {
  if is_truthy "${SKIP_ANSIBLE_INIT:-0}"; then
    log_info "Direct Ansible initialization skipped."
    return
  fi

  local python_cmd

  python_cmd="$(python_bin)" || {
    log_warn "Python was not found; skipping direct Ansible initialization."
    return
  }

  if [[ ! -f "$ANSIBLE_REQUIREMENTS_TXT" ]]; then
    log_warn "Ansible requirements file not found at ${ANSIBLE_REQUIREMENTS_TXT}; skipping direct Ansible initialization."
    return
  fi

  log_info "Initializing Ansible virtual environment at ${ANSIBLE_VENV}."

  "$python_cmd" -m venv "$ANSIBLE_VENV"

  # shellcheck disable=SC1091
  source "$ANSIBLE_VENV/bin/activate"

  python -m pip install --upgrade pip setuptools wheel
  python -m pip install -r "$ANSIBLE_REQUIREMENTS_TXT"

  mkdir -p "$ANSIBLE_COLLECTIONS_DIR" "$ANSIBLE_ROLES_DIR"

  if [[ -f "$ANSIBLE_REQUIREMENTS_YAML" ]]; then
    log_info "Installing Ansible Galaxy collections and roles."

    ansible-galaxy collection install \
      -r "$ANSIBLE_REQUIREMENTS_YAML" \
      -p "$ANSIBLE_COLLECTIONS_DIR" \
      --force

    ansible-galaxy role install \
      -r "$ANSIBLE_REQUIREMENTS_YAML" \
      -p "$ANSIBLE_ROLES_DIR" \
      --force
  fi

  log_success "Direct Ansible initialization complete."
}

run_tasks() {
  if is_truthy "${SKIP_TASKS:-0}"; then
    log_info "Task execution skipped."
    initialize_ansible_direct
    return
  fi

  if ! command_exists task; then
    log_warn "go-task is not installed; falling back to direct Ansible initialization."
    initialize_ansible_direct
    return
  fi

  log_info "Running task ansible:init."

  (
    cd "$REPO_ROOT"
    task ansible:init
  )

  log_success "task ansible:init completed."
}

create_runtime_directories() {
  log_info "Creating repo-local runtime directories."

  mkdir -p \
    "$REPO_ROOT/.outputs" \
    "$ANSIBLE_DIR/.ansible/tmp" \
    "$ANSIBLE_DIR/.ansible/facts" \
    "$ANSIBLE_DIR/.ansible/cp" \
    "$ANSIBLE_COLLECTIONS_DIR" \
    "$ANSIBLE_ROLES_DIR"

  log_success "Runtime directories are ready."
}

print_summary() {
  log_section "Initialization summary"

  log_info "Repository root: ${REPO_ROOT}"
  log_info "Scripts directory: ${SCRIPT_DIR}"
  log_info "Ansible directory: ${ANSIBLE_DIR}"
  log_info "Ansible virtualenv: ${ANSIBLE_VENV}"
  log_info "Brewfile: ${BREWFILE}"
  log_info "Packages file: ${PACKAGES_FILE}"

  if command_exists brew; then
    log_info "Homebrew: $(brew --version | head -n 1)"
  else
    log_warn "Homebrew: not available"
  fi

  if command_exists task; then
    log_info "go-task: $(task --version | head -n 1)"
  else
    log_warn "go-task: not available"
  fi

  if [[ -x "$ANSIBLE_VENV/bin/ansible" ]]; then
    log_info "Ansible: $("$ANSIBLE_VENV/bin/ansible" --version | head -n 1)"
  elif command_exists ansible; then
    log_info "Ansible: $(ansible --version | head -n 1)"
  else
    log_warn "Ansible: not available"
  fi
}

main() {
  log_section "Infrastructure repository initialization"

  require_not_root
  detect_os_distro
  check_internet
  require_sudo
  setup_passwordless_sudo
  install_os_packages
  create_runtime_directories
  install_homebrew
  install_brew_packages
  run_tasks
  print_summary

  log_success "Repository initialization completed successfully."
}

main "$@"