#!/usr/bin/env bash
# Ansible/templates/packer/scripts/install-cloud-init.sh.j2
#
# Install and configure cloud-init for debian-12-template-pve-05.
# Rendered by Ansible into:
#   Packer/debian-12/scripts/install-cloud-init.sh

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

install_cloud_init_packages() {
  log "Installing cloud-init and qemu-guest-agent for ${VM_NAME}"

  retry 5 5 apt-get update

  apt-get install -y \
    cloud-init \
    cloud-guest-utils \
    qemu-guest-agent

  case "${DISTRO_FAMILY}" in
    debian)
      apt-get install -y cloud-initramfs-growroot || {
        warn "cloud-initramfs-growroot unavailable on this Debian image; continuing"
      }
      ;;

    ubuntu)
      apt-get install -y cloud-initramfs-growroot || {
        warn "cloud-initramfs-growroot unavailable on this Ubuntu image; continuing"
      }
      ;;

    *)
      warn "Unknown distro family '${DISTRO_FAMILY}'; installed common cloud-init packages only"
      ;;
  esac
}

configure_cloud_init() {
  log "Configuring cloud-init for Proxmox"

  mkdir -p /etc/cloud/cloud.cfg.d

  cat > /etc/cloud/cloud.cfg.d/99-packer-proxmox.cfg <<'EOF'
# Managed by Packer.
# Prefer Proxmox cloud-init / NoCloud style metadata.
datasource_list: [ NoCloud, ConfigDrive ]
EOF

  cat > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg <<'EOF'
# Managed by Packer.
# Let Proxmox cloud-init drive network configuration at clone time.
network:
  config: disabled
EOF

  # Prevent cloned VMs from reusing installer/template machine identity.
  truncate -s 0 /etc/machine-id || true
  rm -f /var/lib/dbus/machine-id || true
  ln -sf /etc/machine-id /var/lib/dbus/machine-id

  # Keep SSH enabled, but remove host keys so clones generate unique keys.
  rm -f /etc/ssh/ssh_host_* || true
}

reset_cloud_init_state() {
  log "Cleaning cloud-init state for template conversion"

  cloud-init clean --logs --seed || true

  rm -rf /var/lib/cloud/instances/* || true
  rm -rf /var/lib/cloud/instance || true
  rm -rf /var/lib/cloud/seed/* || true
}

enable_services() {
  log "Enabling guest services"

  systemctl enable cloud-init || true
  systemctl enable cloud-config || true
  systemctl enable cloud-final || true
  systemctl enable qemu-guest-agent || true

  # Do not require qemu-guest-agent to be running during image build.
  # It will start normally when the VM boots under Proxmox.
  systemctl start qemu-guest-agent || true
}

main() {
  log "Installing cloud-init support for ${VM_NAME} (${DISTRO})"

  wait_for_apt_locks
  repair_package_state
  install_cloud_init_packages
  configure_cloud_init
  reset_cloud_init_state
  enable_services

  log "cloud-init installation complete for ${VM_NAME}"
}

main "$@"