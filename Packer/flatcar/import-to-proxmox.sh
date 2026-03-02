#!/bin/bash
# Import Flatcar Container Linux image into Proxmox and create template
set -e

# Variables passed from Packer
: "${PROXMOX_NODE:?Required environment variable PROXMOX_NODE not set}"
: "${VM_ID:?Required environment variable VM_ID not set}"
: "${VM_NAME:?Required environment variable VM_NAME not set}"
: "${VM_STORAGE:?Required environment variable VM_STORAGE not set}"
: "${VM_MEMORY:?Required environment variable VM_MEMORY not set}"
: "${VM_CORES:?Required environment variable VM_CORES not set}"
: "${VM_SOCKETS:?Required environment variable VM_SOCKETS not set}"

IMAGE_PATH="/tmp/flatcar_production_qemu_image.img"

echo "Transferring Flatcar image to Proxmox node ${PROXMOX_NODE}..."
scp -o StrictHostKeyChecking=no /tmp/flatcar-download/flatcar_production_qemu_image.img root@${PROXMOX_NODE}:${IMAGE_PATH}

echo "Creating Proxmox VM on ${PROXMOX_NODE}..."
ssh -o StrictHostKeyChecking=no root@${PROXMOX_NODE} bash <<EOF
set -e

# Destroy existing VM if it exists
echo "Checking for existing VM ${VM_ID}..."
qm destroy ${VM_ID} 2>/dev/null || true

# Create new VM
echo "Creating VM ${VM_ID}..."
qm create ${VM_ID} \
  --name "${VM_NAME}" \
  --memory ${VM_MEMORY} \
  --cores ${VM_CORES} \
  --sockets ${VM_SOCKETS} \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket \
  --vga serial0 \
  --ostype l26 \
  --cpu host \
  --agent enabled=0

# Import the disk
echo "Importing disk from ${IMAGE_PATH}..."
qm importdisk ${VM_ID} ${IMAGE_PATH} ${VM_STORAGE}

# Attach the imported disk with virtio-scsi-single controller for iothread support
echo "Attaching disk to VM..."
qm set ${VM_ID} --scsihw virtio-scsi-single --scsi0 ${VM_STORAGE}:vm-${VM_ID}-disk-0,iothread=1

# Set boot order
echo "Configuring boot order..."
qm set ${VM_ID} --boot order=scsi0

# Convert to template
echo "Converting VM to template..."
qm template ${VM_ID}

# Cleanup
echo "Cleaning up temporary files..."
rm -f ${IMAGE_PATH}

echo "Flatcar template ${VM_ID} created successfully!"
EOF
