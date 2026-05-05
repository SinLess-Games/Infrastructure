#!/usr/bin/env bash
# Ansible/templates/packer/scripts/update-system.sh.j2
#
# Update base OS packages for debian-12-template-pve-05.
# Rendered by Ansible into:
#   Packer/debian-12/scripts/update-system.sh

set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

VM_NAME="debian-12-template-pve-05"
DISTRO="debian-12"
DISTRO_FAMILY="debian"

log() {
  echo "==> $*"
}

warn() {
  echo "WARN: $*" >&2
}

retry() {
  local attempts="$1"
  local delay="$2"
  shift 2

  local attempt=1
  until "$@"; do
    if [[ "${attempt}" -ge "${attempts}" ]]; then
      return 1
    fi

    warn "Command failed, retrying in ${delay}s (${attempt}/${attempts}): $*"
    sleep "${delay}"
    attempt=$((attempt + 1))
  done
}

wait_for_apt_locks() {
  local locks=(
    /var/lib/dpkg/lock
    /var/lib/dpkg/lock-frontend
    /var/lib/apt/lists/lock
    /var/cache/apt/archives/lock
  )

  log "Waiting for apt/dpkg locks to clear"

  for _ in $(seq 1 60); do
    local locked=false

    for lock in "${locks[@]}"; do
      if fuser "${lock}" >/dev/null 2>&1; then
        locked=true
        break
      fi
    done

    if [[ "${locked}" == "false" ]]; then
      return 0
    fi

    sleep 5
  done

  warn "Timed out waiting for apt locks; continuing anyway"
}

repair_package_state() {
  log "Repairing package state if needed"

  dpkg --configure -a
  apt-get -f install -y
}

install_base_packages() {
  log "Installing common base packages for ${VM_NAME}"

  apt-get install -y \
    apt-transport-https \
    bash-completion \
    build-essential \
    ca-certificates \
    cloud-guest-utils \
    curl \
    dbus \
    gnupg \
    jq \
    less \
    lsb-release \
    net-tools \
    openssh-server \
    qemu-guest-agent \
    rsync \
    sudo \
    unzip \
    vim \
    wget

  case "${DISTRO_FAMILY}" in
    ubuntu)
      log "Installing Ubuntu-specific kernel headers"
      apt-get install -y linux-headers-generic
      ;;

    debian)
      log "Installing Debian kernel headers"
      apt-get install -y "linux-headers-$(uname -r)" || {
        warn "Exact running kernel headers unavailable; installing generic amd64 headers"
        apt-get install -y linux-headers-amd64
      }
      ;;

    *)
      warn "Unknown distro family '${DISTRO_FAMILY}'; skipping kernel-header family logic"
      ;;
  esac
}

enable_guest_services() {
  log "Enabling guest services"

  systemctl enable ssh || true
  systemctl enable qemu-guest-agent || true
}

cleanup_apt() {
  log "Cleaning apt cache"

  apt-get autoremove -y
  apt-get autoclean -y
  apt-get clean

  rm -rf /var/lib/apt/lists/*
}

main() {
  log "Updating system packages for ${VM_NAME} (${DISTRO})"

  wait_for_apt_locks
  repair_package_state

  log "Refreshing package indexes"
  retry 5 5 apt-get update

  install_base_packages

  log "Upgrading installed packages"
  retry 3 10 apt-get \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    dist-upgrade -y

  enable_guest_services
  cleanup_apt

  log "System update complete for ${VM_NAME}"
}

main "$@"