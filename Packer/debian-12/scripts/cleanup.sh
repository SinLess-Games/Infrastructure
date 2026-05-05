#!/bin/bash
# Ansible/templates/packer/scripts/cleanup.sh.j2
#
# Clean up a guest OS before converting it into a Proxmox template.
#
# This script must be safe across Debian and Ubuntu guests.
# Important:
# - Do not remove /tmp itself. It may be a mounted tmpfs or in-use directory.
# - Clean contents inside /tmp and /var/tmp instead.
# - Keep cleanup best-effort where appropriate so template builds do not fail
#   on harmless service/static-unit warnings.

set -euo pipefail

VM_NAME="debian-12-template-pve-05"
DISTRO="debian-12"
DISTRO_FAMILY="debian"
INSTALLER_TYPE="preseed"

log() {
  echo "==> $*"
}

warn() {
  echo "WARN: $*" >&2
}

run_optional() {
  "$@" || warn "Command failed but is non-fatal: $*"
}

log "Cleaning up ${VM_NAME} (${DISTRO}) for template conversion"

# -----------------------------------------------------------------------------
# Wait for package manager locks
# -----------------------------------------------------------------------------

log "Waiting for apt/dpkg locks to clear"

for lock_file in \
  /var/lib/dpkg/lock \
  /var/lib/dpkg/lock-frontend \
  /var/cache/apt/archives/lock \
  /var/lib/apt/lists/lock
do
  while fuser "${lock_file}" >/dev/null 2>&1; do
    sleep 5
  done
done

log "Repairing package manager state if needed"
run_optional dpkg --configure -a
run_optional apt-get install -f -y

# -----------------------------------------------------------------------------
# Cloud-init cleanup
# -----------------------------------------------------------------------------

if command -v cloud-init >/dev/null 2>&1; then
  log "Cleaning cloud-init state"
  run_optional cloud-init clean --logs --seed
fi

rm -rf /var/lib/cloud/instances/* || true
rm -rf /var/lib/cloud/instance || true
rm -rf /var/lib/cloud/sem/* || true

# -----------------------------------------------------------------------------
# Service state
# -----------------------------------------------------------------------------

log "Ensuring guest services are usable on cloned VMs"

# ssh.service is the real unit on Debian/Ubuntu.
# sshd.service can be a linked alias and may refuse enable operations.
run_optional systemctl enable ssh.service

# qemu-guest-agent may be static on some distros, so enable failures are harmless.
run_optional systemctl enable qemu-guest-agent.service

# Do not hard-fail if cloud-init units differ by distro/version.
for unit in \
  cloud-init-local.service \
  cloud-init.service \
  cloud-config.service \
  cloud-final.service
do
  if systemctl list-unit-files "${unit}" >/dev/null 2>&1; then
    run_optional systemctl enable "${unit}"
  fi
done

# -----------------------------------------------------------------------------
# Machine identity
# -----------------------------------------------------------------------------

log "Resetting machine identity"

rm -f /etc/machine-id /var/lib/dbus/machine-id || true
touch /etc/machine-id

if [ -d /var/lib/dbus ]; then
  ln -sf /etc/machine-id /var/lib/dbus/machine-id || true
fi

# -----------------------------------------------------------------------------
# SSH host keys
# -----------------------------------------------------------------------------

log "Removing SSH host keys"

rm -f /etc/ssh/ssh_host_* || true

# Do not regenerate host keys for a template.
# They should be generated on first boot of each cloned VM.

# -----------------------------------------------------------------------------
# Network state
# -----------------------------------------------------------------------------

log "Cleaning network state"

rm -f /etc/udev/rules.d/70-persistent-net.rules || true
rm -f /var/lib/dhcp/* || true
rm -f /var/lib/NetworkManager/* || true

# Remove installer-generated host keys or DHCP residue if present.
find /etc/systemd/network -type f -name "*.link" -delete 2>/dev/null || true

# -----------------------------------------------------------------------------
# Package manager cleanup
# -----------------------------------------------------------------------------

log "Cleaning package manager state"

export DEBIAN_FRONTEND=noninteractive

run_optional apt-get clean
run_optional apt-get autoclean -y
run_optional apt-get autoremove -y

rm -rf /var/lib/apt/lists/* || true
mkdir -p /var/lib/apt/lists/partial
chmod 755 /var/lib/apt/lists /var/lib/apt/lists/partial

# -----------------------------------------------------------------------------
# Logs
# -----------------------------------------------------------------------------

log "Cleaning logs"

run_optional journalctl --rotate
run_optional journalctl --vacuum-time=1s

find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true

rm -rf /var/log/journal/* || true
rm -rf /run/log/journal/* || true

# -----------------------------------------------------------------------------
# Shell history
# -----------------------------------------------------------------------------

log "Cleaning shell history"

unset HISTFILE || true
history -c 2>/dev/null || true

rm -f /root/.bash_history /root/.zsh_history || true
find /home -maxdepth 2 \( -name ".bash_history" -o -name ".zsh_history" \) -delete 2>/dev/null || true

# -----------------------------------------------------------------------------
# Temporary files and caches
# -----------------------------------------------------------------------------

log "Cleaning temporary files and caches"

# Never delete /tmp or /var/tmp themselves.
# They may be mount points or required system directories.
find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
find /var/tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true

mkdir -p /tmp /var/tmp
chmod 1777 /tmp /var/tmp

rm -rf /root/.cache/* || true
find /home -maxdepth 2 -type d -name ".cache" -exec rm -rf {}/* \; 2>/dev/null || true

# -----------------------------------------------------------------------------
# Installer leftovers
# -----------------------------------------------------------------------------

log "Removing installer leftovers"

rm -f /root/anaconda-ks.cfg || true
rm -f /root/install.log || true
rm -f /root/install.log.syslog || true
rm -rf /target || true

# -----------------------------------------------------------------------------
# Sync filesystem
# -----------------------------------------------------------------------------

log "Syncing filesystem"

sync

log "Cleanup for ${VM_NAME} complete"