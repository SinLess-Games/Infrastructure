# Kubernetes Development Deployment - Vault Integration Guide

## Required Vault Secrets Structure

The `deploy-kubernetes-dev.yaml` playbook requires two Vault secrets to be preconfigured before deployment.

### 1. Kubernetes Development Configuration
**Path:** `secrets/data/kubernetes/development`

This secret should contain configuration needed to bootstrap the RKE2 cluster:

```hcl
# Vault KV v2 secret structure
kubernetes/development
├── rke2_server_token     # RKE2 cluster join token (required)
├── vault_addr            # Vault address for cluster components (optional)
└── vault_kv_path         # Vault KV path for cluster access (optional)
```

**How to create this secret:**

```bash
# Using Vault CLI
vault kv put secrets/kubernetes/development \
  rke2_server_token="K1234567890abcdefghijklmnopqrst" \
  vault_addr="https://10.10.10.180:8200" \
  vault_kv_path="kubernetes/development"

# Or using HTTP API
curl -X POST https://10.10.10.180:8200/v1/secrets/data/kubernetes/development \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  -d '{
    "data": {
      "rke2_server_token": "K1234567890abcdefghijklmnopqrst",
      "vault_addr": "https://10.10.10.180:8200",
      "vault_kv_path": "kubernetes/development"
    }
  }'
```

### 2. Ansible Kubernetes Configuration  
**Path:** `secrets/data/ansible/kubernetes/development`

This secret contains SSH keys for provisioning the Kubernetes nodes:

```hcl
# Vault KV v2 secret structure
ansible/kubernetes/development
└── kubernetes_ssh_keys  # Array of SSH public keys (required)
    ├── ssh-rsa AAAAB3NzaC1yc2E... (key 1)
    └── ssh-rsa AAAAB3NzaC1yc2E... (key 2)
```

**How to create this secret:**

```bash
# Generate SSH key pair (if needed)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/kubernetes-dev-key -N ""

# Create Vault secret with SSH keys
vault kv put secrets/ansible/kubernetes/development \
  'kubernetes_ssh_keys=["ssh-rsa AAAAB3NzaC1yc2E...FirstKey...", "ssh-rsa AAAAB3NzaC1yc2E...SecondKey..."]'

# Or using HTTP API with jq
cat > /tmp/k8s-keys.json << 'EOF'
{
  "data": {
    "kubernetes_ssh_keys": [
      "ssh-rsa AAAAB3NzaC1yc2E... key1@ansible",
      "ssh-rsa AAAAB3NzaC1yc2E... key2@ansible"
    ]
  }
}
EOF

curl -X POST https://10.10.10.180:8200/v1/secrets/data/ansible/kubernetes/development \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  -d @/tmp/k8s-keys.json
```

## Vault Integration in Playbook

The playbook uses the existing `Ansible/tasks/vault.yaml` task which:

1. **Loads Vault defaults** from environment or group_vars:
   - `vault_addr` - Vault server address
   - `vault_kv_mount` - KV mount point (default: "secrets")
   - `vault_kv_path` - Path to secrets
   - `vault_skip_verify` - TLS verification (true for dev)
   - `vault_token` - Auth token from environment

2. **Walks Vault metadata tree** using `Ansible/tasks/_vault_walk_step.yaml`:
   - Discovers all secrets under the specified path
   - Reads each secret document
   - Merges all keys into `vault_runtime_secrets`

3. **Exposes as variables** in subsequent tasks:
   - `vault_kubernetes_development_data` - Contains RKE2 config
   - `vault_kubernetes_ansible_development_data` - Contains SSH keys

## Testing Vault Access

Before running the full deployment, verify Vault is accessible:

```bash
# 1. Set environment variables
export VAULT_ADDR="https://10.10.10.180:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN="<your-valid-token>"

# 2. Check Vault health
curl -sk $VAULT_ADDR/v1/sys/health -H "X-Vault-Token: $VAULT_TOKEN" | jq .

# 3. List kubernetes secrets
vault kv list secrets/kubernetes

# 4. Read specific secret
vault kv get secrets/kubernetes/development
vault kv get secrets/ansible/kubernetes/development

# 5. Run test playbook
ansible-playbook -i Ansible/inventory Ansible/playbooks/test-vault-integration.yaml
```

## Deployment Command

Once Vault secrets are configured:

```bash
# Set environment variables
export VAULT_ADDR="https://10.10.10.180:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN="<your-valid-token>"

# Run deployment
ansible-playbook -i Ansible/inventory \
  Ansible/playbooks/deploy-kubernetes-dev.yaml \
  --extra-vars "kubernetes_wait_for_ssh_timeout=1200"

# Or with verbosity
ansible-playbook -i Ansible/inventory \
  Ansible/playbooks/deploy-kubernetes-dev.yaml \
  --extra-vars "kubernetes_wait_for_ssh_timeout=1200" \
  -v
```

## Troubleshooting

### Vault secrets not found
- Verify Vault is unsealed: `vault status`
- Verify auth token is valid: `vault token lookup`
- Verify secrets path exists: `vault kv list secrets/kubernetes`
- Check Vault audit logs for authentication errors

### SSH key issues
- Ensure SSH keys are in proper OpenSSH format (start with `ssh-rsa`)
- Test SSH key locally: `ssh-keygen -l -f <key-file>`
- Verify key array is valid JSON

### RKE2 token issues
- Generate valid RKE2 token: `openssl rand -hex 32`
- Ensure token is stored as string, not object

## References

- Vault Documentation: https://www.vaultproject.io/docs
- RKE2 Documentation: https://docs.rke2.io/
- Ansible vault.yaml task: `Ansible/tasks/vault.yaml`
- Kubernetes group vars: `Ansible/group_vars/kubernetes/development/main.yaml`
