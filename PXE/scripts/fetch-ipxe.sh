#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# fetch-ipxe.sh
# - Downloads iPXE binaries into PXE/docker/tftp
# - Verifies downloads (basic sanity checks)
# - Sets safe permissions for TFTP
# - Supports mirrors + optional pinned commit builds (if you later add them)
# -----------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TFTP_DIR="$ROOT_DIR/docker/tftp"

# You can override these via env if needed
: "${IPXE_BASE_URL:=https://boot.ipxe.org}"
: "${CURL:=curl}"

# What we fetch
FILES=(
  "undionly.kpxe"
  "ipxe.efi"
  "snponly.efi"
)

mkdir -p "$TFTP_DIR"

log() { printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

fetch_one() {
  local name="$1"
  local url="$2"
  local tmp
  tmp="$(mktemp)"

  log "Downloading: $name"
  # -f: fail on HTTP errors
  # -S: show error
  # -L: follow redirects
  # --retry: tolerate transient failures
  "$CURL" -fSL --retry 5 --retry-delay 1 --connect-timeout 5 --max-time 120 \
    -o "$tmp" "$url" || {
      rm -f "$tmp"
      die "Failed download: $url"
    }

  # Basic sanity checks (avoid serving HTML error pages via TFTP)
  local size
  size="$(wc -c <"$tmp" | tr -d ' ')"
  if [[ "$size" -lt 16384 ]]; then
    rm -f "$tmp"
    die "Downloaded file too small ($size bytes): $name from $url"
  fi

  # If 'file' exists, use it for an extra check
  if command -v file >/dev/null 2>&1; then
    local ftype
    ftype="$(file -b "$tmp" || true)"
    if echo "$ftype" | grep -qiE 'HTML|text'; then
      rm -f "$tmp"
      die "Downloaded content looks wrong ($ftype): $name from $url"
    fi
  fi

  mv -f "$tmp" "$TFTP_DIR/$name"
}

main() {
  need_cmd "$CURL"

  log "Fetching iPXE binaries into: $TFTP_DIR"
  log "Base URL: $IPXE_BASE_URL"

  # Download each file
  for f in "${FILES[@]}"; do
    fetch_one "$f" "$IPXE_BASE_URL/$f"
  done

  # Make TFTP root traversable + files world-readable (common TFTP requirement)
  chmod 755 "$TFTP_DIR" || true
  chmod 644 "$TFTP_DIR/"*.efi "$TFTP_DIR/"*.kpxe 2>/dev/null || true

  log "Downloaded:"
  ls -lah "$TFTP_DIR"/undionly.kpxe "$TFTP_DIR"/ipxe.efi "$TFTP_DIR"/snponly.efi

  log "OK: iPXE binaries ready in $TFTP_DIR"
}

main "$@"
