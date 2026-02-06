#!/bin/bash
# Clean up template for deployment

set -e
set -x

echo "Cleaning up system for template..."

# Remove cloud-init state
cloud-init clean -s -l

# Remove machine-specific files
rm -f /etc/machine-id /var/lib/dbus/machine-id
touch /etc/machine-id

# Clear SSH keys (will be regenerated)
rm -f /etc/ssh/ssh_host_*
ssh-keygen -A

# Clear history
history -c
cat /dev/null > ~/.bash_history

# Clean package cache
DEBIAN_FRONTEND=noninteractive apt-get clean
DEBIAN_FRONTEND=noninteractive apt-get autoclean -y
DEBIAN_FRONTEND=noninteractive apt-get autoremove -y

# Remove any temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/log/*
rm -rf /root/.cache/*

# Clear DHCP leases
rm -f /var/lib/dhcp/*

echo "Template cleanup complete."
