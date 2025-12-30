#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HTTP_DIR="$ROOT/docker/http/www"
REL="${DEBIAN_RELEASE:-bookworm}"
ARCH="${DEBIAN_ARCH:-amd64}"

OUT="$HTTP_DIR/debian/$REL/$ARCH"
mkdir -p "$OUT"

echo "Fetching Debian netboot for $REL/$ARCH..."
# Debian netboot artifacts
BASE_URL="https://deb.debian.org/debian/dists/$REL/main/installer-$ARCH/current/images/netboot/debian-installer/$ARCH"
curl -fsSL -o "$OUT/linux" "$BASE_URL/linux"
curl -fsSL -o "$OUT/initrd.gz" "$BASE_URL/initrd.gz"

echo "OK: Debian netboot artifacts in $OUT"
