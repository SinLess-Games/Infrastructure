#!/bin/bash
# Quick reference for Vault operations
# Location: scripts/vault-operations.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VAULT_ADDR="${VAULT_ADDR:-https://127.0.0.1:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"

print_header() {
    echo -e "\n${GREEN}=== $1 ===${NC}\n"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Initialize Vault (run once on first node)
init_vault() {
    print_header "Initializing Vault"
    
    if [ -z "$1" ]; then
        KEY_SHARES=5
        KEY_THRESHOLD=3
    else
        KEY_SHARES=$1
        KEY_THRESHOLD=$2
    fi
    
    echo "Key Shares: $KEY_SHARES"
    echo "Key Threshold: $KEY_THRESHOLD"
    
    vault operator init \
        -key-shares=$KEY_SHARES \
        -key-threshold=$KEY_THRESHOLD \
        -format=json | tee init-output.json
    
    echo -e "\n${GREEN}Vault initialized!${NC}"
    echo "Root token and unseal keys saved to init-output.json"
    print_warning "Keep this file secure and move it to .outputs/vault/"
}

# Unseal Vault
unseal_vault() {
    print_header "Unsealing Vault"
    
    if [ ! -f "$1" ]; then
        print_error "Unseal keys file not found: $1"
        exit 1
    fi
    
    # Extract and apply first 3 keys (if threshold is 3)
    KEYS=$(jq -r '.keys_b64[]' "$1" | head -3)
    
    for key in $KEYS; do
        echo "Unsealing with key: ${key:0:10}..."
        vault operator unseal "$key" || true
    done
    
    # Check status
    vault status
}

# Check cluster status
cluster_status() {
    print_header "Cluster Status"
    
    echo "Raft Peers:"
    vault operator raft list-peers -format=json | jq .
    
    echo -e "\n${GREEN}Vault Status:${NC}"
    vault status -format=json | jq '{initialized, sealed, ha_enabled, node_address}'
}

# Initialize auth methods
setup_auth() {
    print_header "Setting up Auth Methods"
    
    # Enable userpass auth
    vault auth enable userpass || true
    echo -e "${GREEN}✓ Userpass auth enabled${NC}"
    
    # Enable OIDC (for Authentik)
    vault auth enable oidc || true
    echo -e "${GREEN}✓ OIDC auth enabled${NC}"
    
    # Enable Kubernetes auth
    vault auth enable kubernetes || true
    echo -e "${GREEN}✓ Kubernetes auth enabled${NC}"
}

# Setup basic policies
setup_policies() {
    print_header "Setting up Policies"
    
    # Admin policy
    cat > /tmp/admin-policy.hcl <<EOF
path "*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF
    
    vault policy write admin /tmp/admin-policy.hcl
    echo -e "${GREEN}✓ Admin policy created${NC}"
    
    # Read-only policy
    cat > /tmp/readonly-policy.hcl <<EOF
path "*" {
  capabilities = ["read", "list"]
}
EOF
    
    vault policy write readonly /tmp/readonly-policy.hcl
    echo -e "${GREEN}✓ Readonly policy created${NC}"
    
    rm /tmp/admin-policy.hcl /tmp/readonly-policy.hcl
}

# Enable secrets engines
setup_secrets() {
    print_header "Setting up Secrets Engines"
    
    # KV v2 for general secrets
    vault secrets enable -version=2 -path=secret kv || true
    echo -e "${GREEN}✓ KV v2 secrets engine enabled at /secret${NC}"
    
    # Database (for credentials)
    vault secrets enable database || true
    echo -e "${GREEN}✓ Database secrets engine enabled${NC}"
    
    # SSH (for SSH key management)
    vault secrets enable ssh || true
    echo -e "${GREEN}✓ SSH secrets engine enabled${NC}"
}

# Show audit logs
show_audit_logs() {
    print_header "Recent Audit Logs"
    
    if [ -z "$1" ]; then
        NODE="vault-01"
    else
        NODE=$1
    fi
    
    ssh "root@$NODE" "tail -100 /var/log/vault/audit.log | jq ." 2>/dev/null || \
    ssh "root@$NODE" "tail -100 /var/log/vault/audit.log"
}

# Backup Raft snapshot
backup_raft() {
    print_header "Backing up Raft Snapshot"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="vault-raft-snapshot-${TIMESTAMP}.snap"
    
    vault operator raft snapshot save "$BACKUP_FILE"
    
    if [ -f "$BACKUP_FILE" ]; then
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo -e "${GREEN}✓ Snapshot saved: $BACKUP_FILE ($SIZE)${NC}"
        echo "Keep this file for disaster recovery"
    else
        print_error "Failed to create snapshot"
        exit 1
    fi
}

# Restore Raft snapshot
restore_raft() {
    print_header "Restoring Raft Snapshot"
    
    if [ -z "$1" ]; then
        print_error "Usage: vault_ops restore_raft <snapshot_file>"
        exit 1
    fi
    
    if [ ! -f "$1" ]; then
        print_error "Snapshot file not found: $1"
        exit 1
    fi
    
    print_warning "This will overwrite the current state!"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        vault operator raft snapshot restore "$1"
        echo -e "${GREEN}✓ Snapshot restored${NC}"
    else
        echo "Cancelled"
    fi
}

# Remove sealed node from cluster
remove_node() {
    print_header "Removing Node from Cluster"
    
    if [ -z "$1" ]; then
        print_error "Usage: vault_ops remove_node <node_id>"
        exit 1
    fi
    
    vault operator raft remove-peer "$1"
    echo -e "${GREEN}✓ Node $1 removed from cluster${NC}"
}

# Display unseal keys
show_keys() {
    print_header "Unseal Keys & Root Token"
    
    if [ -f ".outputs/vault/unseal-keys.json" ]; then
        echo "Unseal Keys:"
        jq '.keys_b64 | .[]' .outputs/vault/unseal-keys.json | head -3
        echo -e "\nKey Threshold: $(jq '.keys | length' .outputs/vault/unseal-keys.json) shares"
    else
        print_error "Unseal keys file not found"
    fi
    
    if [ -f ".outputs/vault/root-token.json" ]; then
        echo -e "\nRoot Token:"
        jq '.root_token' .outputs/vault/root-token.json
    else
        print_error "Root token file not found"
    fi
}

# Display help
show_help() {
    cat <<EOF
${GREEN}Vault Operations Script${NC}

Usage: $0 <command> [options]

Commands:
  init_vault [shares] [threshold]   Initialize Vault (run once)
  unseal_vault <keys_file>          Unseal Vault with keys from file
  cluster_status                     Show cluster and raft status
  setup_auth                         Enable auth methods
  setup_policies                     Create basic policies
  setup_secrets                      Enable secrets engines
  show_audit_logs [node]             Show audit logs from node
  backup_raft                        Create Raft snapshot backup
  restore_raft <snapshot_file>       Restore from Raft snapshot
  remove_node <node_id>              Remove sealed node from cluster
  show_keys                          Display unseal keys and root token
  help                               Show this help message

Examples:
  $0 init_vault 5 3
  $0 cluster_status
  $0 backup_raft
  $0 show_audit_logs vault-01

Environment Variables:
  VAULT_ADDR=${VAULT_ADDR}
  VAULT_SKIP_VERIFY=${VAULT_SKIP_VERIFY}

EOF
}

# Main
case "${1:-help}" in
    init_vault)
        shift
        init_vault "$@"
        ;;
    unseal_vault)
        shift
        unseal_vault "$@"
        ;;
    cluster_status)
        cluster_status
        ;;
    setup_auth)
        setup_auth
        ;;
    setup_policies)
        setup_policies
        ;;
    setup_secrets)
        setup_secrets
        ;;
    show_audit_logs)
        shift
        show_audit_logs "$@"
        ;;
    backup_raft)
        backup_raft
        ;;
    restore_raft)
        shift
        restore_raft "$@"
        ;;
    remove_node)
        shift
        remove_node "$@"
        ;;
    show_keys)
        show_keys
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
