#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# fetch-debian-netboot.sh
# - Downloads Debian installer netboot kernel + initrd into PXE/docker/http/www
# - Adds retries, mirrors, sanity checks, optional checksum verification
# - Safe atomic writes (tmp -> mv) to avoid partial files
# -----------------------------------------------------------------------------

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HTTP_DIR="$ROOT/docker/http/www"

REL="${DEBIAN_RELEASE:-bookworm}"
ARCH="${DEBIAN_ARCH:-amd64}"

OUT="$HTTP_DIR/debian/$REL/$ARCH"
mkdir -p "$OUT"

: "${CURL:=curl}"
: "${DEBIAN_MIRROR:=https://deb.debian.org/debian}"

log() { printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

# Debian netboot artifacts (standard dists path)
BASE_PATH="dists/$REL/main/installer-$ARCH/current/images/netboot/debian-installer/$ARCH"
BASE_URL="$DEBIAN_MIRROR/$BASE_PATH"

# Atomic download helper with sanity checks
fetch_one() {
  local name="$1"
  local url="$2"
  local tmp
  tmp="$(mktemp)"

  log "Downloading: $name"
  "$CURL" -fSL --retry 6 --retry-delay 1 --connect-timeout 5 --max-time 180 \
    -o "$tmp" "$url" || {
      rm -f "$tmp"
      die "Failed download: $url"
    }

  # Sanity check: ensure we didn't download an HTML error page
  local size
  size="$(wc -c <"$tmp" | tr -d ' ')"
  if [[ "$size" -lt 65536 ]]; then
    # kernel can be >~ 6MB usually, initrd often >~ 20MB, so 64KB is a safe floor
    rm -f "$tmp"
    die "Downloaded file too small ($size bytes): $name from $url"
  fi

  if command -v file >/dev/null 2>&1; then
    local ftype
    ftype="$(file -b "$tmp" || true)"
    if echo "$ftype" | grep -qiE 'HTML|text'; then
      rm -f "$tmp"
      die "Downloaded content looks wrong ($ftype): $name from $url"
    fi
  fi

  mv -f "$tmp" "$OUT/$name"
}

# Optional: try to verify against SHA256SUMS if present at the same level
# This is best-effort; if it fails to download/parse, we continue.
verify_sha256_best_effort() {
  local sums_url="$BASE_URL/SHA256SUMS"
  local sums_tmp
  sums_tmp="$(mktemp)"

  log "Attempting checksum verification (best-effort)..."
  if ! "$CURL" -fSL --retry 3 --retry-delay 1 --connect-timeout 5 --max-time 60 \
      -o "$sums_tmp" "$sums_url" 2>/dev/null; then
    rm -f "$sums_tmp"
    log "No SHA256SUMS available at: $sums_url (skipping verification)"
    return 0
  fi

  # Extract expected sums for linux and initrd.gz
  local linux_sum initrd_sum
  linux_sum="$(awk '$2 ~ /(^|\/)linux$/ {print $1; exit}' "$sums_tmp" || true)"
  initrd_sum="$(awk '$2 ~ /(^|\/)initrd\.gz$/ {print $1; exit}' "$sums_tmp" || true)"
  rm -f "$sums_tmp"

  if [[ -z "$linux_sum" || -z "$initrd_sum" ]]; then
    log "SHA256SUMS did not contain linux/initrd.gz entries (skipping verification)"
    return 0
  fi

  need_cmd sha256sum

  local got_linux got_initrd
  got_linux="$(sha256sum "$OUT/linux" | awk '{print $1}')"
  got_initrd="$(sha256sum "$OUT/initrd.gz" | awk '{print $1}')"

  if [[ "$got_linux" != "$linux_sum" ]]; then
    die "Checksum mismatch for linux: expected $linux_sum got $got_linux"
  fi
  if [[ "$got_initrd" != "$initrd_sum" ]]; then
    die "Checksum mismatch for initrd.gz: expected $initrd_sum got $got_initrd"
  fi

  log "Checksum OK."
}

main() {
  need_cmd "$CURL"

  log "Fetching Debian netboot for $REL/$ARCH"
  log "Output dir: $OUT"
  log "Mirror: $DEBIAN_MIRROR"
  log "URL base: $BASE_URL"

  fetch_one "linux"     "$BASE_URL/linux"
  fetch_one "initrd.gz" "$BASE_URL/initrd.gz"

  verify_sha256_best_effort

  log "Downloaded:"
  ls -lah "$OUT/linux" "$OUT/initrd.gz"

  log "OK: Debian netboot artifacts ready in $OUT"
}

main "$@"
