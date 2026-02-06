#!/bin/bash
# Download OS ISOs to Proxmox ISOs storage
# Easily add more ISOs by editing the ISO_SOURCES associative array below

set -e

# ============================================================================
# Color Configuration
# ============================================================================
readonly COLOR_RESET='\033[0m'
readonly COLOR_BLACK='\033[0;30m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_WHITE='\033[0;37m'

readonly COLOR_BOLD_RED='\033[1;31m'
readonly COLOR_BOLD_GREEN='\033[1;32m'
readonly COLOR_BOLD_YELLOW='\033[1;33m'
readonly COLOR_BOLD_BLUE='\033[1;34m'
readonly COLOR_BOLD_CYAN='\033[1;36m'

# ============================================================================
# Logging Functions
# ============================================================================
log_info() {
  echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
  echo -e "${COLOR_GREEN}[✓]${COLOR_RESET} ${COLOR_GREEN}$*${COLOR_RESET}"
}

log_error() {
  echo -e "${COLOR_BOLD_RED}[✗ ERROR]${COLOR_RESET} ${COLOR_RED}$*${COLOR_RESET}" >&2
}

log_warning() {
  echo -e "${COLOR_BOLD_YELLOW}[⚠ WARNING]${COLOR_RESET} ${COLOR_YELLOW}$*${COLOR_RESET}"
}

log_debug() {
  [[ "${DEBUG:-0}" == "1" ]] && echo -e "${COLOR_MAGENTA}[DEBUG]${COLOR_RESET} $*"
}

print_header() {
  echo -e "\n${COLOR_BOLD_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}"
  echo -e "${COLOR_BOLD_CYAN}$*${COLOR_RESET}"
  echo -e "${COLOR_BOLD_CYAN}═══════════════════════════════════════════════════════════${COLOR_RESET}\n"
}

print_section() {
  echo -e "\n${COLOR_BOLD_BLUE}➜ $*${COLOR_RESET}"
}

# ============================================================================
# Safe Arithmetic Helpers (avoid set -e surprises)
# ============================================================================
inc() {
  local -n _var=$1
  _var=$((_var + 1))
}

# ============================================================================
# Helper Functions
# ============================================================================
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=5)

fetch_url() {
  local url=$1
  if command -v curl >/dev/null 2>&1; then
    if [[ "${ALLOW_INSECURE_CHECKSUMS:-0}" == "1" ]]; then
      curl -kfsSL "$url"
    else
      curl -fsSL "$url"
    fi
  elif command -v wget >/dev/null 2>&1; then
    if [[ "${ALLOW_INSECURE_CHECKSUMS:-0}" == "1" ]]; then
      wget --no-check-certificate -q -O - "$url"
    else
      wget -q -O - "$url"
    fi
  else
    log_error "Neither curl nor wget is available to fetch ${url}"
    return 1
  fi
}

fetch_url_remote() {
  local url=$1
  local remote_cmd
  if [[ "${ALLOW_INSECURE_CHECKSUMS:-0}" == "1" ]]; then
    remote_cmd="(command -v curl >/dev/null 2>&1 && curl -kfsSL '${url}') || (command -v wget >/dev/null 2>&1 && wget --no-check-certificate -q -O - '${url}')"
  else
    remote_cmd="(command -v curl >/dev/null 2>&1 && curl -fsSL '${url}') || (command -v wget >/dev/null 2>&1 && wget -q -O - '${url}')"
  fi
  ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" "${remote_cmd}" 2>/dev/null
}

resolve_checksum() {
  local iso_filename=$1
  local iso_checksum=$2
  local iso_url=$3
  local iso_sums=$4

  if [[ "${iso_checksum}" != "AUTO" ]]; then
    echo "${iso_checksum}"
    return 0
  fi

  local sums_url
  if [[ -n "${iso_sums}" ]]; then
    if [[ "${iso_sums}" == http* ]]; then
      sums_url="${iso_sums}"
    else
      sums_url="${iso_url}${iso_sums}"
    fi
  else
    sums_url="${iso_url}SHA256SUMS"
  fi

  local sums
  if ! sums="$(fetch_url "${sums_url}")"; then
    log_warning "Local checksum fetch failed, trying via Proxmox node..."
    if ! sums="$(fetch_url_remote "${sums_url}")"; then
      log_error "Failed to fetch checksum file: ${sums_url}"
      return 1
    fi
  fi

  local expected
  expected=$(echo "${sums}" | awk -v f="${iso_filename}" '{
    gsub(/^\*/,"",$2)
    gsub(/^\.\//,"",$2)
    if ($2==f) {print $1; exit}
  }')
  if [[ -z "${expected}" ]]; then
    expected=$(echo "${sums}" | awk -v f="${iso_filename}" '
      $0 ~ /^SHA256 \(/ {
        sub(/^SHA256 \(/,"",$0)
        sub(/\) = /," ",$0)
        if ($1==f) {print $2; exit}
      }')
  fi
  if [[ -z "${expected}" ]]; then
    log_error "Could not find checksum for ${iso_filename} in ${sums_url}"
    return 1
  fi

  echo "${expected}"
}

# ============================================================================
# Proxmox Configuration
# ============================================================================
PROXMOX_NODE="${PROXMOX_NODE:-pve-01}"
PROXMOX_ENDPOINT="${PROXMOX_ENDPOINT:-https://proxmox.local.sinlessgames.com}"
PROXMOX_ISO_PATH="${PROXMOX_ISO_PATH:-/mnt/pve/ISOs}"
PROXMOX_ISO_PATH_BASE="${PROXMOX_ISO_PATH}"
PROXMOX_STORAGE_ID="${PROXMOX_STORAGE_ID:-ISOs}"

# Try to resolve node IP (fallback to node name if resolution fails)
PROXMOX_NODE_IP="${PROXMOX_NODE_IP:-$(getent hosts "${PROXMOX_NODE}" 2>/dev/null | awk '{print $1}')}"
[[ -z "${PROXMOX_NODE_IP}" ]] && PROXMOX_NODE_IP="${PROXMOX_NODE}"

detect_remote_iso_path() {
  # For 'dir' storage, ISO images typically live under template/iso
  if ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" \
    "test -d '${PROXMOX_ISO_PATH}/template/iso'" > /dev/null 2>&1; then
    PROXMOX_ISO_PATH="${PROXMOX_ISO_PATH}/template/iso"
  fi
}

warn_misplaced_isos() {
  if [[ "${PROXMOX_ISO_PATH}" == "${PROXMOX_ISO_PATH_BASE}/template/iso" ]]; then
    if ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" \
      "ls '${PROXMOX_ISO_PATH_BASE}'/*.iso >/dev/null 2>&1"; then
      log_warning "ISO files found in ${PROXMOX_ISO_PATH_BASE}. Proxmox expects them in ${PROXMOX_ISO_PATH}"
    fi
  fi
}

# ============================================================================
# ISO DEFINITIONS - Easy to add more!
# Format: ["name"]="filename|checksum|download_url|checksum_file(optional)"
# ============================================================================
declare -A ISO_SOURCES=(
  # Debian netinst ISOs (lightweight, minimal)
  ["debian-12"]="debian-12.13.0-amd64-netinst.iso|AUTO|https://cloudfront.debian.net/cdimage/archive/latest-oldstable/amd64/iso-cd/|SHA256SUMS"
  ["debian-13"]="debian-13.3.0-amd64-netinst.iso|AUTO|https://cloudfront.debian.net/cdimage/release/current/amd64/iso-cd/|SHA256SUMS"
  
  # Flatcar Linux - Stable Release v4459.2.3 (lightweight container OS)
  # Suitable for Kubernetes and container-based deployments
  ["flatcar"]="flatcar_production_qemu_image.img.bz2|4a30f4929e84879ab6f99fbed1e480c0994580548aebafe221f9ad98f53be60c|https://stable.release.flatcar-linux.net/amd64-usr/current/"
  
  # ========== COMMENTED EXAMPLES - Uncomment and fill in values to enable ==========
  # Ubuntu Server ISOs (fill in actual checksum from official Ubuntu downloads)
  # ["ubuntu-22.04"]="ubuntu-22.04.3-live-server-amd64.iso|AUTO|https://releases.ubuntu.com/22.04.3/|SHA256SUMS"
  ["ubuntu-24.04"]="ubuntu-24.04.3-live-server-amd64.iso|AUTO|https://releases.ubuntu.com/24.04.3/|SHA256SUMS"
  
  # Proxmox Backup Server
  ["pbs"]="proxmox-backup-server_4.1-1.iso|AUTO|http://download.proxmox.com/iso/|SHA256SUMS"
  
  # Proxmox Mail Gateway
  ["pmg"]="proxmox-mail-gateway_8.2-1.iso|AUTO|http://download.proxmox.com/iso/|SHA256SUMS"
  
  # Kali Linux (direct HTTP ISO)
  ["kali"]="kali-linux-2025.4-installer-amd64.iso|AUTO|https://cdimage.kali.org/kali-2025.4/|SHA256SUMS"
)

# Default to downloading all available ISOs (sorted alphabetically)
ISOS_TO_DOWNLOAD=($(printf '%s\n' "${!ISO_SOURCES[@]}" | sort))

# Parse arguments
if [[ $# -gt 0 ]]; then
  ISOS_TO_DOWNLOAD=()
  for iso_name in "$@"; do
    if [[ -n "${ISO_SOURCES[$iso_name]}" ]]; then
      ISOS_TO_DOWNLOAD+=("$iso_name")
    else
      log_error "Unknown ISO '${COLOR_BOLD_YELLOW}${iso_name}${COLOR_RED}'"
      echo -e "${COLOR_YELLOW}Available ISOs:${COLOR_RESET}"
      printf '%s\n' "${!ISO_SOURCES[@]}" | sort | sed 's/^/  • /'
      exit 1
    fi
  done
fi

# Function to download and verify ISO
download_iso() {
  local iso_name=$1
  local iso_info="${ISO_SOURCES[$iso_name]}"
  
  # Parse ISO info
  local iso_filename=$(echo "$iso_info" | cut -d'|' -f1)
  local iso_checksum=$(echo "$iso_info" | cut -d'|' -f2)
  local iso_url=$(echo "$iso_info" | cut -d'|' -f3)
  local iso_sums=$(echo "$iso_info" | cut -d'|' -f4)
  local expected_checksum
  expected_checksum="$(resolve_checksum "${iso_filename}" "${iso_checksum}" "${iso_url}" "${iso_sums}")" || return 1
  
  print_section "Downloading ${COLOR_BOLD_CYAN}${iso_name}${COLOR_RESET}"
  log_debug "Filename: ${iso_filename}"
  log_debug "URL: ${iso_url}${iso_filename}"
  if [[ "${iso_filename}" != *.iso ]]; then
    log_warning "${iso_filename} is not an ISO. It will not appear under ISO Images in the Proxmox UI."
  fi

  # Skip download if ISO already exists on Proxmox node and checksum matches
  if ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" \
    "test -f '${PROXMOX_ISO_PATH}/${iso_filename}'" > /dev/null 2>&1; then
    log_info "Remote ISO found, verifying checksum..."
    local remote_checksum
    remote_checksum=$(ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" \
      "sha256sum '${PROXMOX_ISO_PATH}/${iso_filename}' 2>/dev/null | awk '{print \$1}'")
    if [[ -z "${remote_checksum}" ]]; then
      log_warning "Could not read remote checksum, proceeding to download"
    elif [[ "${remote_checksum}" == "${expected_checksum}" ]]; then
      log_success "${iso_filename} already exists on ${PROXMOX_NODE} and checksum matches - skipping download"
      return 0
    else
      log_warning "Remote checksum mismatch, re-downloading ISO"
      log_info "Expected: ${expected_checksum}"
      log_info "Remote:   ${remote_checksum}"
    fi
  fi
  
  # Prefer downloading directly on Proxmox node
  log_info "Downloading on Proxmox node ${COLOR_CYAN}${PROXMOX_NODE}${COLOR_RESET} (${PROXMOX_NODE_IP})..."
  if ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" \
    "wget -q --show-progress '${iso_url}${iso_filename}' -O '${PROXMOX_ISO_PATH}/${iso_filename}'"; then
    log_success "Downloaded on Proxmox node"

    log_info "Verifying SHA256 checksum on Proxmox node..."
    local remote_checksum
    remote_checksum=$(ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" \
      "sha256sum '${PROXMOX_ISO_PATH}/${iso_filename}' 2>/dev/null | awk '{print \$1}'")
    if [[ "${remote_checksum}" == "${expected_checksum}" ]]; then
      log_success "Checksum verified"
    else
      log_error "Checksum verification failed on Proxmox node!"
      log_info "Expected: ${expected_checksum}"
      log_info "Remote:   ${remote_checksum:-<empty>}"
      ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" \
        "rm -f '${PROXMOX_ISO_PATH}/${iso_filename}'" > /dev/null 2>&1 || true
      return 1
    fi
  else
    log_warning "Remote download failed, falling back to local download + SCP"

    # Download ISO locally
    log_info "Downloading ${COLOR_CYAN}${iso_filename}${COLOR_RESET}..."
    if ! wget -q --show-progress "${iso_url}${iso_filename}" -O "/tmp/${iso_filename}"; then
      log_error "Failed to download ISO"
      log_info "URL: ${iso_url}${iso_filename}"
      log_info "Verify the URL is accessible and the file exists"
      return 1
    fi

    # Get file size
    local file_size=$(du -h "/tmp/${iso_filename}" | cut -f1)
    log_success "Downloaded (${file_size})"

    # Verify checksum
    log_info "Verifying SHA256 checksum..."
    if echo "${expected_checksum}  /tmp/${iso_filename}" | sha256sum -c - > /dev/null 2>&1; then
      log_success "Checksum verified"
    else
      log_error "Checksum verification failed!"
      log_info "Expected: ${expected_checksum}"
      local actual_checksum=$(sha256sum "/tmp/${iso_filename}" | awk '{print $1}')
      log_info "Actual:   ${actual_checksum}"
      rm -f "/tmp/${iso_filename}"
      return 1
    fi

    # Copy to Proxmox ISOs storage via SSH
    log_info "Copying to Proxmox node ${COLOR_CYAN}${PROXMOX_NODE}${COLOR_RESET} (${PROXMOX_NODE_IP})..."
    if scp "/tmp/${iso_filename}" "root@${PROXMOX_NODE_IP}:${PROXMOX_ISO_PATH}/" > /dev/null 2>&1; then
      log_success "Copied to ${PROXMOX_ISO_PATH}/"
    else
      log_warning "Could not copy via SCP to ${PROXMOX_ISO_PATH}/"
      log_info "Attempting alternate path..."
      if scp "/tmp/${iso_filename}" "root@${PROXMOX_NODE_IP}:/iso/" > /dev/null 2>&1; then
        log_success "Copied to /iso/ (alternate path)"
      else
        log_error "Could not copy ISO to Proxmox node ${PROXMOX_NODE} (${PROXMOX_NODE_IP})"
        log_info "Verify SSH connectivity: ${COLOR_CYAN}ssh root@${PROXMOX_NODE_IP}${COLOR_RESET}"
        return 1
      fi
    fi

    # Cleanup local copy
    rm -f "/tmp/${iso_filename}"
    log_debug "Cleaned up temporary file"
  fi
  
  log_success "${iso_name} ISO ready!"
}

# Main execution
print_header "OS ISO Download Utility"

detect_remote_iso_path
warn_misplaced_isos

log_info "Configuration:"
log_info "  Proxmox Node:  ${COLOR_CYAN}${PROXMOX_NODE}${COLOR_RESET} (${PROXMOX_NODE_IP})"
log_info "  ISO Storage:   ${COLOR_CYAN}${PROXMOX_ISO_PATH}${COLOR_RESET}"
log_info "  ISOs to sync:  ${COLOR_CYAN}${ISOS_TO_DOWNLOAD[*]}${COLOR_RESET}"
echo ""

# Track successes and failures
SUCCESSFUL=0
FAILED=0
FAILED_ISOS=()
NEEDS_REFRESH=0

for iso_name in "${ISOS_TO_DOWNLOAD[@]}"; do
  if download_iso "$iso_name"; then
    inc SUCCESSFUL
    NEEDS_REFRESH=1
  else
    inc FAILED
    FAILED_ISOS+=("$iso_name")
  fi
  echo ""
done

refresh_proxmox_storage() {
  if [[ "${NEEDS_REFRESH}" -eq 0 ]]; then
    return 0
  fi
  if ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" "command -v pvesm >/dev/null 2>&1"; then
    log_info "Refreshing Proxmox storage index..."
    ssh "${SSH_OPTS[@]}" "root@${PROXMOX_NODE_IP}" "pvesm scan '${PROXMOX_STORAGE_ID}' >/dev/null 2>&1" \
      || log_warning "Could not refresh storage index (pvesm scan ${PROXMOX_STORAGE_ID})"
  fi
}

refresh_proxmox_storage

# Print summary
print_header "Download Summary"
log_info "Total ISOs:      ${COLOR_CYAN}${#ISOS_TO_DOWNLOAD[@]}${COLOR_RESET}"
log_success "Successful:     ${SUCCESSFUL}"

if [[ ${FAILED} -eq 0 ]]; then
  log_success "All ISO downloads complete!"
  exit 0
else
  log_error "Failed:         ${FAILED}"
  echo -e "\n${COLOR_YELLOW}Failed ISOs:${COLOR_RESET}"
  printf '%s\n' "${FAILED_ISOS[@]}" | sed 's/^/  • /'
  exit 1
fi
