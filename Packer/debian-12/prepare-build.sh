#!/usr/bin/env bash
# Ansible/templates/packer/prepare-build.sh.j2
#
# Prepare debian-12 template build for pve-05.
# This script is rendered by Ansible and written into:
#   Packer/debian-12/prepare-build.sh

set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Rendered build metadata
# -----------------------------------------------------------------------------

DISTRO="debian-12"
VM_NAME="debian-12-template-pve-05"
PROXMOX_NODE="pve-05"
ISO_URL="https://cloudfront.debian.net/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-12.13.0-amd64-netinst.iso"
ISO_FILENAME="debian-12.13.0-amd64-netinst.iso"
ISO_HOST="cloudfront.debian.net"
PACKER_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${PACKER_PROJECT_DIR}/../.." && pwd)"

# Optional checksum support.
# If you add iso_checksum to a distro in Ansible/group_vars/packer/main.yaml,
# render it here later as:
# ISO_CHECKSUM=""
ISO_CHECKSUM=""

# Cache ISO locally before upload/copy.
ISO_CACHE_DIR="${PACKER_ISO_CACHE_DIR:-${REPO_ROOT}/Packer/.iso-cache}"
LOCAL_ISO_PATH="${ISO_CACHE_DIR}/${ISO_FILENAME}"

# Packer var-files / credentials.
# Supports both spellings because old scripts used .pkvars.hcl.
CREDENTIAL_FILES=(
  "${REPO_ROOT}/Packer/credentials.pkrvars.hcl"
  "${REPO_ROOT}/Packer/credentials.pkvars.hcl"
  "${REPO_ROOT}/credentials.pkrvars.hcl"
  "${REPO_ROOT}/credentials.pkvars.hcl"
)

# -----------------------------------------------------------------------------
# Output helpers
# -----------------------------------------------------------------------------

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m"

log() {
  echo -e "${BLUE}==>${NC} $*"
}

ok() {
  echo -e "${GREEN}OK:${NC} $*"
}

warn() {
  echo -e "${YELLOW}WARN:${NC} $*"
}

err() {
  echo -e "${RED}ERROR:${NC} $*" >&2
}

die() {
  err "$*"
  exit 1
}

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    die "Required command not found: ${command_name}"
  fi
}

extract_hcl_string() {
  local key="$1"
  local file="$2"

  awk -v key="${key}" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      gsub(/^[[:space:]]*"|"[[:space:]]*$/, "", $3)
      print $3
      exit
    }
  ' "${file}" 2>/dev/null || true
}

find_credentials_file() {
  local file

  for file in "${CREDENTIAL_FILES[@]}"; do
    if [[ -f "${file}" ]]; then
      echo "${file}"
      return 0
    fi
  done

  return 1
}

download_iso() {
  mkdir -p "${ISO_CACHE_DIR}"

  if [[ -f "${LOCAL_ISO_PATH}" ]]; then
    ok "ISO already exists: ${LOCAL_ISO_PATH}"
    return 0
  fi

  log "Downloading ISO"
  echo "  URL:  ${ISO_URL}"
  echo "  File: ${LOCAL_ISO_PATH}"

  if command -v curl >/dev/null 2>&1; then
    curl \
      --fail \
      --location \
      --progress-bar \
      --retry 5 \
      --retry-delay 3 \
      --output "${LOCAL_ISO_PATH}.tmp" \
      "${ISO_URL}"
  elif command -v wget >/dev/null 2>&1; then
    wget \
      --tries=5 \
      --continue \
      --progress=bar:force \
      --output-document="${LOCAL_ISO_PATH}.tmp" \
      "${ISO_URL}"
  else
    die "Neither curl nor wget is installed."
  fi

  mv "${LOCAL_ISO_PATH}.tmp" "${LOCAL_ISO_PATH}"
  ok "Downloaded ISO: ${LOCAL_ISO_PATH}"
}

verify_iso_checksum() {
  if [[ -z "${ISO_CHECKSUM}" ]]; then
    warn "No ISO checksum configured for ${DISTRO}; skipping checksum verification."
    return 0
  fi

  require_command sha256sum

  log "Verifying ISO checksum"
  local actual_checksum
  actual_checksum="$(sha256sum "${LOCAL_ISO_PATH}" | awk '{print $1}')"

  if [[ "${actual_checksum}" != "${ISO_CHECKSUM}" ]]; then
    cat >&2 <<EOF
Checksum mismatch for ${LOCAL_ISO_PATH}

Expected: ${ISO_CHECKSUM}
Actual:   ${actual_checksum}
EOF
    exit 1
  fi

  ok "Checksum verified"
}

print_detected_credentials() {
  local credentials_file
  credentials_file="$(find_credentials_file || true)"

  if [[ -z "${credentials_file}" ]]; then
    warn "No Packer credentials var-file found."
    warn "Expected one of:"
    for file in "${CREDENTIAL_FILES[@]}"; do
      echo "  - ${file}"
    done
    return 0
  fi

  log "Detected credentials file: ${credentials_file}"

  local endpoint
  local node
  local iso_storage

  endpoint="$(extract_hcl_string proxmox_endpoint "${credentials_file}")"
  node="$(extract_hcl_string proxmox_node "${credentials_file}")"
  iso_storage="$(extract_hcl_string proxmox_iso_storage "${credentials_file}")"

  echo "  proxmox_endpoint: ${endpoint:-not set}"
  echo "  proxmox_node:     ${node:-not set}"
  echo "  iso_storage:      ${iso_storage:-not set}"
}

print_upload_guidance() {
  cat <<EOF

${BLUE}ISO placement requirement${NC}

The generated Packer HCL expects this ISO to already exist in Proxmox storage:

  \${var.proxmox_iso_storage}:iso/${ISO_FILENAME}

Local cached ISO:

  ${LOCAL_ISO_PATH}

If this workstation is not the Proxmox node, upload the ISO to the Proxmox ISO
storage before running packer build.

Common options:

  # Option 1: Upload through the Proxmox UI
  Datacenter -> Storage -> ISO Images -> Upload

  # Option 2: Copy directly to a Proxmox node ISO storage path
  scp "${LOCAL_ISO_PATH}" root@${PROXMOX_NODE}:/var/lib/vz/template/iso/${ISO_FILENAME}

  # Option 3: If the ISO storage is mounted locally on the Proxmox node
  cp "${LOCAL_ISO_PATH}" /var/lib/vz/template/iso/${ISO_FILENAME}

EOF
}

print_next_steps() {
  cat <<EOF

${GREEN}Preparation complete for ${DISTRO}${NC}

Packer project:

  ${PACKER_PROJECT_DIR}

Template VM:

  ${VM_NAME}

Target Proxmox node:

  ${PROXMOX_NODE}

Run from the Packer project directory:

  cd "${PACKER_PROJECT_DIR}"
  packer init .
  packer validate -var-file="../../Ansible/generated/packer/${DISTRO}-template-${PROXMOX_NODE}.pkrvars.hcl" .
  packer build -var-file="../../Ansible/generated/packer/${DISTRO}-template-${PROXMOX_NODE}.pkrvars.hcl" .

Or run through Ansible:

  task ansible:deploy-template-vms

EOF
}

main() {
  log "Preparing ${DISTRO} Packer build"
  echo "  Distro:      ${DISTRO}"
  echo "  VM name:     ${VM_NAME}"
  echo "  Node:        ${PROXMOX_NODE}"
  echo "  ISO host:    ${ISO_HOST}"
  echo "  ISO URL:     ${ISO_URL}"
  echo "  ISO file:    ${ISO_FILENAME}"
  echo "  Project dir: ${PACKER_PROJECT_DIR}"
  echo "  Repo root:   ${REPO_ROOT}"
  echo ""

  print_detected_credentials
  echo ""

  download_iso
  verify_iso_checksum
  print_upload_guidance
  print_next_steps
}

main "$@"