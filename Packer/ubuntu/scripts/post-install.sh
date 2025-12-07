#!/usr/bin/env bash
# Packer/ubuntu/scripts/post-install.sh
# Post-install script for Ubuntu server templates — run as root inside the VM

set -euo pipefail
LOGFILE="/var/log/packer-post-install.log"
exec &> >(tee -a "$LOGFILE")

echo "=== Ubuntu post-install started: $(date) ==="

########################
# 1. Update + Upgrade  #
########################

echo "-- Updating package lists and upgrading packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
apt-get dist-upgrade -y -qq

########################
# 2. Install default tools / extras
########################

echo "-- Installing essential tools and utilities..."
apt-get install -y -qq \
    nano \
    zsh \
    git \
    curl \
    wget \
    unzip \
    htop \
    net-tools \
    ufw \
    locales \
    tzdata

########################
# 3. Configure timezone & locale (example: America/Denver)
########################

echo "-- Configuring locale and timezone..."
ln -fs /usr/share/zoneinfo/America/Denver /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
update-locale LANG=en_US.UTF-8

########################
# 4. Basic system hardening / housekeeping
########################

# 4a. UFW — basic firewall default setup
echo "-- Configuring UFW firewall defaults..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# 4b. Clean up apt caches and logs
echo "-- Cleaning apt cache and unnecessary files..."
apt-get autoremove -y -qq
apt-get clean -qq
rm -rf /var/lib/apt/lists/*

# 4c. Clean shell histories, tmp, logs
echo "-- Cleaning history, temp and log files..."
history -cw || true
: > /root/.bash_history
if [ -f "/home/ubuntu/.bash_history" ]; then
  : > /home/ubuntu/.bash_history
fi
rm -rf /tmp/* /var/tmp/*

########################
# 5. Zero-out free disk space (shrink filesystem / image size)
########################

echo "-- Zeroing free disk space to help compact disk image/template..."
if command -v dd &>/dev/null; then
  dd if=/dev/zero of=/zerofill.tmp bs=1M || true
  sync
  rm -f /zerofill.tmp
  sync
fi

########################
# 6. Enable / validate SSH & zsh default shell
########################

echo "-- Ensuring SSH service enabled and setting default shell for ubuntu user..."
systemctl enable ssh
systemctl restart ssh

if id ubuntu &>/dev/null; then
  chsh -s /usr/bin/zsh ubuntu || true
fi

########################
# 7. Final cleanup and zero-out machine-specific IDs
########################

echo "-- Cleaning cloud-init & machine-id to avoid duplicate machine identity on clones..."
if command -v cloud-init &>/dev/null; then
  cloud-init clean --logs
fi
: > /etc/machine-id
echo '' > /var/lib/dbus/machine-id || true

echo "=== Ubuntu post-install completed: $(date) ==="
