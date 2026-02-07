#!/usr/bin/env bash
# =============================================================================
# Vault Environment Setup Helper
# =============================================================================
# Usage: source scripts/vault-env.sh
#
# This script sets up Vault environment variables for local CLI usage.
# After sourcing, you can use the vault CLI without specifying --address
# =============================================================================

# Vault API address (VIP)
export VAULT_ADDR="${VAULT_ADDR:-https://10.10.10.180:8200}"

# Skip TLS verification (for self-signed certs)
export VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load Vault CA certificate if available
VAULT_CA_PATH="$PROJECT_ROOT/.outputs/vault/vault-ca.pem"
if [[ -f "$VAULT_CA_PATH" ]]; then
  export VAULT_CACERT="$VAULT_CA_PATH"
  echo "✓ Using CA certificate: $VAULT_CACERT"
fi

# Load Vault root token if available (use with caution)
VAULT_KEYS_FILE="$PROJECT_ROOT/.outputs/vault/unseal-keys.json"
if [[ -f "$VAULT_KEYS_FILE" ]]; then
  VAULT_TOKEN_VALUE="$(jq -r '.root_token' "$VAULT_KEYS_FILE" 2>/dev/null || true)"
  if [[ -n "$VAULT_TOKEN_VALUE" && "$VAULT_TOKEN_VALUE" != "null" ]]; then
    export VAULT_TOKEN="$VAULT_TOKEN_VALUE"
    echo "✓ Vault token loaded from unseal-keys.json"
  fi
fi

echo ""
echo "Vault environment configured:"
echo "  VAULT_ADDR:        $VAULT_ADDR"
echo "  VAULT_SKIP_VERIFY: $VAULT_SKIP_VERIFY"
[[ -n "${VAULT_CACERT:-}" ]] && echo "  VAULT_CACERT:      Set"
[[ -n "${VAULT_TOKEN:-}" ]] && echo "  VAULT_TOKEN:       Set (root token)"
echo ""
echo "You can now use vault CLI commands without specifying --address"
echo "Example: vault status"
