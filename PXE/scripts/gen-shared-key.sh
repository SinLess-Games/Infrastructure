#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS="$ROOT/secrets"
mkdir -p "$SECRETS"

KEY="$SECRETS/provisioning_key"
if [[ -f "$KEY" ]]; then
  echo "Key already exists: $KEY"
  exit 0
fi

ssh-keygen -t ed25519 -N "" -f "$KEY" -C "pxe-provisioning"
echo "OK: generated $KEY and $KEY.pub"
