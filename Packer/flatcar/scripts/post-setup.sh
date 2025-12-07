#!/usr/bin/env bash
# Packer/flatcar/scripts/post-setup.sh
# Post-provisioning / post-install script for Flatcar VM templates
# Run as root inside the VM after first boot & ignition are done

set -euo pipefail
LOG="/var/log/flatcar-post-setup.log"
exec &> >(tee -a "$LOG")

echo "=== Flatcar post-setup started: $(date) ==="

# 1. Update etc/hostname, hosts, timezone if needed
#    (Assumes /etc/hostname is already set by ignition)
HOSTNAME="$(cat /etc/hostname 2>/dev/null || echo flatcar-vm)"
echo "Setting hostname to '$HOSTNAME'"
hostnamectl set-hostname "$HOSTNAME" --static

# Optional: adjust hosts file (basic)
if ! grep -q "$HOSTNAME" /etc/hosts; then
  echo "127.0.0.1   $HOSTNAME localhost" >> /etc/hosts
  echo "::1         $HOSTNAME localhost ip6-localhost ip6-loopback" >> /etc/hosts
fi

# 2. (Optional) Configure sysctl tweaks — example: disable IPv6 if desired
#   Uncomment or adjust as needed
# echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.d/99-disable-ipv6.conf
# sysctl -p /etc/sysctl.d/99-disable-ipv6.conf

# 3. (Optional) Add swap — if you want a swapfile (Flatcar is minimal by default)
#    WARNING: use swap only when necessary (e.g. memory-constrained workloads)
# SWAP_FILE="/swapfile"
# SWAP_SIZE_GB=2
# if [ ! -f "$SWAP_FILE" ]; then
#   echo "Creating swapfile ($SWAP_SIZE_GB G)..."
#   fallocate -l "${SWAP_SIZE_GB}G" "$SWAP_FILE"
#   chmod 600 "$SWAP_FILE"
#   mkswap "$SWAP_FILE"
#   swapon "$SWAP_FILE"
#   echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
#   echo "Swapfile created and enabled."
# fi

# 4. (Optional) Install container runtimes or helper tools (docker, podman, etc.)
#    Flatcar is immutable and does not include a package manager — so you should
#    use static binaries, container runtimes shipped as containers, or distro-agnostic install flows.
#    If you include container runtimes, make sure to use official instructions or binary packages.

# Example placeholder for pulling docker-compose if needed:
# echo "Installing docker-compose..."
# DOCKER_COMPOSE_VERSION="v2.23.3"
# curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
#     -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose

# 5. Clean up any temporary or build-specific files, logs, history before templating
echo "Cleaning up temporary files and shell history..."
rm -rf /var/tmp/* /tmp/*
: > /root/.bash_history
: > /home/core/.bash_history 2>/dev/null || true

# 6. Zero-out unused disk space (optional — helps reduce template/quota size)
if command -v dd &>/dev/null; then
  echo "Zeroing free disk space to shrink template..."
  dd if=/dev/zero of=/zerofill.tmp bs=1M || true
  sync
  rm -f /zerofill.tmp
  sync
fi

echo "=== Flatcar post-setup completed: $(date) ==="
