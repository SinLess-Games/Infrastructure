#!/bin/bash
# Generate Ansible inventory for Vault cluster
# This script is called by Terraform to generate the vault-prod.yaml inventory file

set -e

# Parse nodes from JSON
NODES=$(echo "$NODES_JSON" | jq -r '.[] | "\(.name):\(.ip_address):\(.node_index):\(.is_leader)"')

# Create inventory file
cat > "$INVENTORY_PATH" <<EOF
---
vault_${ENVIRONMENT}:
  hosts:
EOF

# Add each host
echo "$NODES" | while IFS=':' read -r name ip index is_leader; do
  cat >> "$INVENTORY_PATH" <<EOF
    $name:
      ansible_host: $ip
      ansible_user: $ANSIBLE_USER
      vault_node_id: $name
      vault_node_index: $index
      vault_cluster_name: $CLUSTER_NAME
      vault_api_addr: "https://$ip:$VAULT_PORT"
      vault_cluster_addr: "https://$ip:$VAULT_CLUSTER_PORT"
      vault_raft_leader: $is_leader
EOF
done

# Add group vars
cat >> "$INVENTORY_PATH" <<EOF
  vars:
    vault_version: "$VAULT_VERSION"
    vault_port: $VAULT_PORT
    vault_cluster_port: $VAULT_CLUSTER_PORT
    vault_storage_path: "$VAULT_STORAGE_PATH"
    vault_log_path: "$VAULT_LOG_PATH"
    vault_tls_enabled: $VAULT_TLS_ENABLED
    vault_environment: "$ENVIRONMENT"
EOF

echo "Generated inventory: $INVENTORY_PATH"
