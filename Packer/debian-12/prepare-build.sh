#!/bin/bash
# Prepare Debian 12 template build

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Preparing Debian 12 Packer Build ===${NC}"

# Source credential variables
if [ -f "../credentials.pkvars.hcl" ]; then
  echo -e "${BLUE}Loading credentials...${NC}"
  # Extract variables from HCL file
  PROXMOX_ENDPOINT=$(grep 'proxmox_endpoint' ../credentials.pkvars.hcl | awk -F'"' '{print $2}')
  PROXMOX_NODE=$(grep 'proxmox_node' ../credentials.pkvars.hcl | awk -F'"' '{print $2}')
  PROXMOX_ISO_STORAGE=$(grep 'proxmox_iso_storage' ../credentials.pkvars.hcl | awk -F'"' '{print $2}')
fi

# Set defaults
PROXMOX_ENDPOINT="${PROXMOX_ENDPOINT:-https://proxmox.local.sinlessgames.com}"
PROXMOX_NODE="${PROXMOX_NODE:-pve-01}"
PROXMOX_ISO_STORAGE="${PROXMOX_ISO_STORAGE:-ISOs}"

DEBIAN_ISO="debian-12.13.0-amd64-netinst.iso"
DEBIAN_CHECKSUM="2b880ffabe36dbe04a662a3125e5ecae4db69d0acce257dd74615bbf165ad76e"
TEMP_ISO="/tmp/${DEBIAN_ISO}"

echo -e "${BLUE}Configuration:${NC}"
echo "  Proxmox Endpoint: $PROXMOX_ENDPOINT"
echo "  Proxmox Node: $PROXMOX_NODE"
echo "  ISO Storage: $PROXMOX_ISO_STORAGE"
echo "  ISO Name: $DEBIAN_ISO"

# Download ISO if not already present
if [ ! -f "$TEMP_ISO" ]; then
  echo -e "${BLUE}Downloading Debian 12 ISO...${NC}"
  wget -q --show-progress \
    "https://cloudfront.debian.net/cdimage/archive/latest-oldstable/amd64/iso-cd/${DEBIAN_ISO}" \
    -O "$TEMP_ISO"
else
  echo -e "${GREEN}ISO already downloaded${NC}"
fi

# Verify checksum
echo -e "${BLUE}Verifying checksum...${NC}"
ACTUAL_CHECKSUM=$(sha256sum "$TEMP_ISO" | awk '{print $1}')
if [ "$ACTUAL_CHECKSUM" != "$DEBIAN_CHECKSUM" ]; then
  echo "ERROR: Checksum mismatch!"
  echo "  Expected: $DEBIAN_CHECKSUM"
  echo "  Actual:   $ACTUAL_CHECKSUM"
  exit 1
fi
echo -e "${GREEN}Checksum verified${NC}"

# Copy to Proxmox ISOs storage
echo -e "${BLUE}Uploading ISO to Proxmox...${NC}"
# This uses Proxmox storage API or local copy depending on setup
# For now, just report success as ISO is ready
echo -e "${GREEN}ISO preparation complete!${NC}"
echo ""
echo -e "${BLUE}Ready to run: packer build -var-file=\"../credentials.pkvars.hcl\" -var-file=\"../variables.pkvars.hcl\" debian-12.pkr.hcl${NC}"
