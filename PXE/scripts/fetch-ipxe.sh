#!/usr/bin/env bash
set -euo pipefail

TFTP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker/tftp"
OUT="$TFTP_DIR/bootloaders"
mkdir -p "$OUT"

echo "Fetching iPXE binaries..."
# Official iPXE builds (may change over time). If a URL breaks, update here.
curl -fsSL -o "$OUT/undionly.kpxe" https://boot.ipxe.org/undionly.kpxe
curl -fsSL -o "$OUT/ipxe.efi" https://boot.ipxe.org/ipxe.efi
curl -fsSL -o "$OUT/snponly.efi" https://boot.ipxe.org/snponly.efi

# Copy into tftp root as expected by dnsmasq.conf
cp -f "$OUT/undionly.kpxe" "$TFTP_DIR/undionly.kpxe"
cp -f "$OUT/ipxe.efi" "$TFTP_DIR/ipxe.efi"
cp -f "$OUT/snponly.efi" "$TFTP_DIR/snponly.efi"

echo "OK: iPXE binaries in $TFTP_DIR"
