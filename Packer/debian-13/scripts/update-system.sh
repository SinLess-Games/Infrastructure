#!/bin/bash
# Update system packages

set -e
set -x

echo "Updating system packages..."
apt-get update
apt-get install -y linux-headers-generic build-essential

echo "Performing upgrade..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "System update complete."
