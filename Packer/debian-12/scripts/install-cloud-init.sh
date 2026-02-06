#!/bin/bash
# Install cloud-init for cloud provisioning support

set -e
set -x

echo "Installing cloud-init and qemu-guest-agent..."
DEBIAN_FRONTEND=noninteractive apt-get install -y cloud-init cloud-initramfs-growroot qemu-guest-agent

echo "Configuring cloud-init..."
cat > /etc/cloud/cloud.cfg.d/99-packer.cfg <<EOF
datasource_list: [ ConfigDrive, NoCloud ]
EOF

echo "cloud-init installation complete."

echo "Starting qemu-guest-agent..."
systemctl start qemu-guest-agent
