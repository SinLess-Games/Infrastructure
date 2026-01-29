# ACME Certificate Management - Complete Setup Summary

## What's Been Configured

Your Proxmox cluster now has a complete, automated ACME certificate management system ready to use. All Ansible variables are pre-populated with your `sinlessgames.com` domain and Cloudflare DNS provider.

### Configuration Status

✅ **Certificate Role Created**
- Location: `Ansible/roles/proxmox-certs/`
- Supports: Self-signed, ACME (Let's Encrypt), and manual certificates
- Status: Ready for deployment

✅ **Variables Pre-Populated**
- Location: `Ansible/group_vars/proxmox/certificate.yaml`
- Domain: `sinlessgames.com` and variants
- Email: `admin@sinlessgames.com`
- DNS Provider: Cloudflare (auto-configured)
- Status: Ready to enable

✅ **Secrets Template Created**
- Location: `Ansible/group_vars/proxmox/vault-certs.yaml`
- Contains: Cloudflare API token placeholder
- Status: Needs your API token

✅ **Playbook Updated**
- Location: `Ansible/playbooks/setup-proxmox-nodes.yaml`
- Added: `proxmox-certs` role with tags
- Added: certificate.yaml to vars_files
- Status: Ready to run

✅ **Documentation Created**
- `Docs/Start-Here/09-ACME-Certificate-Management.md` - Complete setup guide
- `Docs/Start-Here/ACME-Field-Mapping.md` - Ansible to Proxmox UI variable mapping
- Status: Ready for reference

## How It Works

### Current Architecture

```
Self-Signed Certificates (DEFAULT)
└─→ Generated immediately on first deployment
    └─→ Used by proxmox-ha-ui for load balancer
        └─→ UI accessible at https://10.10.10.14

Optional: ACME/Let's Encrypt Setup
└─→ Enable by setting proxmox_acme_enabled: true
    └─→ Ansible configures account and DNS plugin in Proxmox
        └─→ You request certificate via Proxmox UI
            └─→ Automatic DNS validation via Cloudflare
                └─→ Certificate installed on Proxmox nodes
```

### What Gets Auto-Filled

When you enable ACME and run the Ansible playbook, these Proxmox UI fields are **automatically populated**:

**Datacenter → ACME → Accounts:**
- Account Name: `default`
- Email: `admin@sinlessgames.com`
- ACME Directory: Let's Encrypt Production URL

**Datacenter → ACME → Plugins:**
- Plugin ID: `dns_cloudflare`
- Type: DNS
- DNS API: `cloudflare`
- API Data: `CF_Token=...` (from vault)

**Node → Certificates:**
- Certificate CN: `proxmox.sinlessgames.com`
- SANs include: `*.sinlessgames.com`, `sinlessgames.com`, etc.

## Quick Start (3 Steps)

### Step 1: Get Cloudflare API Token

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use template: "Edit Zone DNS"
4. Grant: Zone DNS Edit on your domain
5. Copy the token

### Step 2: Add Token to Vault

```bash
# Edit vault file
ansible-vault edit Ansible/group_vars/proxmox/vault-certs.yaml

# Add or replace this line:
vault_cloudflare_dns_token: "CF_Token=YOUR_TOKEN_HERE"

# Save and exit (Ctrl+X in nano, :wq in vim)
```

### Step 3: Enable and Deploy

Edit `Ansible/group_vars/proxmox/certificate.yaml`:

Change line 58 from:
```yaml
proxmox_acme_enabled: false
```

To:
```yaml
proxmox_acme_enabled: true
```

Then run:
```bash
ansible-playbook Ansible/playbooks/setup-proxmox-nodes.yaml \
  --tags proxmox,certs \
  --ask-vault-pass
```

When prompted, enter your vault password.

## What This Deploys

### On Each Proxmox Node

1. **ACME Account Registration** (Proxmox API → /etc/pve/acme/)
   - Account: `default` (for Let's Encrypt notifications)
   - Email notifications sent to `admin@sinlessgames.com`

2. **DNS Plugin Configuration** (Proxmox API → /etc/pve/acme/)
   - DNS provider: Cloudflare
   - API credentials stored securely in Proxmox

3. **Certificate Management** (Ansible tasks)
   - Backs up existing certificates
   - Sets up auto-renewal checks
   - Configures service restart on certificate update

### In Proxmox UI

**Immediately visible after deployment:**
- Datacenter → ACME → Accounts: Shows "default" account registered
- Datacenter → ACME → Plugins: Shows "dns_cloudflare" plugin available
- Node → Certificates → Status: Ready to request

**Available for you to use:**
- Node → Certificates → "Order Certificate Now" button becomes functional
- Certificate will be requested from Let's Encrypt
- DNS validation happens automatically
- Certificate installs automatically

## File Locations & Changes

### Modified Files
```
Ansible/playbooks/setup-proxmox-nodes.yaml
├── Added: certificate.yaml to vars_files (line 30)
└── Added: proxmox-certs role with tags (lines 67-71)
```

### New Configuration Files
```
Ansible/group_vars/proxmox/
├── certificate.yaml          (NEW - 156 lines, pre-populated)
└── vault-certs.yaml          (NEW - encrypted, has placeholder)
```

### New Documentation
```
Docs/Start-Here/
├── 09-ACME-Certificate-Management.md    (NEW - 500+ lines)
└── ACME-Field-Mapping.md                (NEW - complete reference)
```

### Existing Role (Enhanced)
```
Ansible/roles/proxmox-certs/
├── tasks/main.yaml           (includes ACME configuration tasks)
├── handlers/main.yaml        (service restart handlers)
├── defaults/main.yaml        (certificate management defaults)
├── meta/main.yaml            (role metadata)
└── README.md                 (comprehensive documentation)
```

## Next Steps

### Immediate (After enabling ACME)

1. ✅ Vault API token added to `vault-certs.yaml`
2. ✅ `proxmox_acme_enabled` set to `true`
3. ✅ Run playbook: `ansible-playbook ... --tags proxmox,certs --ask-vault-pass`
4. ✅ Verify: Proxmox UI shows ACME account and plugin registered

### Short-term (Certificate Request)

1. ✅ Log in to Proxmox UI
2. ✅ Go to Node (e.g., pve-01) → Certificates → Proxmox VE Certificate
3. ✅ Click "Order Certificate Now"
4. ✅ Proxmox requests from Let's Encrypt
5. ✅ DNS validation happens automatically
6. ✅ Certificate installs automatically

### Long-term (Operations)

- **Automatic renewal:** Certificate renewed 30 days before expiration
- **Notifications:** Renewal status sent to `admin@sinlessgames.com`
- **Backups:** Old certificates backed up (last 5 versions kept)
- **Monitoring:** Check `/var/log/pveproxy/access.log` for errors

## Important Configuration Values

| Parameter | Value | Location |
|-----------|-------|----------|
| Certificate Source | `"self-signed"` (default) | certificate.yaml line 20 |
| ACME Enabled | `false` (default, set to `true` to enable) | certificate.yaml line 58 |
| Domain | `sinlessgames.com` | certificate.yaml line 49 |
| Email | `admin@sinlessgames.com` | certificate.yaml line 84 |
| DNS Provider | `cloudflare` | certificate.yaml line 105 |
| Plugin ID | `dns_cloudflare` | certificate.yaml line 103 |
| Renewal Threshold | `30` days | certificate.yaml line 137 |
| Backup Count | `5` versions | certificate.yaml line 142 |

## Variable Dependencies

```
To enable ACME, you need:

certificate.yaml:
├── proxmox_acme_enabled = true
├── proxmox_acme_email = "admin@sinlessgames.com" ✓
├── proxmox_acme_dns_api = "cloudflare" ✓
├── proxmox_acme_plugin_id = "dns_cloudflare" ✓
└── proxmox_acme_dns_api_data = vault_cloudflare_dns_token
    └── vault-certs.yaml:
        └── vault_cloudflare_dns_token = "CF_Token=..." ← YOU ADD THIS

Additional for Proxmox API:
├── proxmox_acme_password = root password
    └── Option 1: Pass as `-e proxmox_acme_password=...`
    └── Option 2: Add to vault_proxmox_root_password in vault-certs.yaml
```

## Troubleshooting Quick Links

See full documentation for detailed troubleshooting:

| Issue | Solution |
|-------|----------|
| ACME account not showing in UI | Check `proxmox_acme_password` is set |
| DNS validation fails | Verify Cloudflare token in vault-certs.yaml |
| Certificate request pending | Check Proxmox logs: `tail -f /var/log/pveproxy/access.log` |
| "Token reference not found" error | Run playbook with `--ask-vault-pass` |
| Want to test before production | Set `proxmox_acme_provider_staging: true` |

## Example: Enabling ACME Right Now

1. **Edit certificate.yaml:**
   ```bash
   nano Ansible/group_vars/proxmox/certificate.yaml
   # Find line 58: proxmox_acme_enabled: false
   # Change to: proxmox_acme_enabled: true
   # Save: Ctrl+O, Enter, Ctrl+X
   ```

2. **Edit vault (if you have token):**
   ```bash
   ansible-vault edit Ansible/group_vars/proxmox/vault-certs.yaml
   # Replace "your-cloudflare-api-token-here" with your actual token
   # Example: CF_Token=abcd1234efgh5678ijkl9012mnop3456
   ```

3. **Run playbook:**
   ```bash
   cd /home/sinless777/Projects/Infrastructure
   ansible-playbook Ansible/playbooks/setup-proxmox-nodes.yaml \
     --tags proxmox,certs \
     --ask-vault-pass \
     -e proxmox_acme_password=YOUR_PROXMOX_ROOT_PASSWORD
   ```

4. **Verify in Proxmox UI:**
   - Navigate to: Datacenter → ACME → Accounts
   - Should see account "default" registered
   - Should show email: admin@sinlessgames.com

## Documentation Reference

- 📖 **Complete Setup Guide:** `Docs/Start-Here/09-ACME-Certificate-Management.md`
- 🗺️ **Variable Mapping:** `Docs/Start-Here/ACME-Field-Mapping.md`
- 📝 **Certificate Role Docs:** `Ansible/roles/proxmox-certs/README.md`
- 🔧 **HA UI Role Docs:** `Ansible/roles/proxmox-ha-ui/README.md`
- 🎯 **Configuration File:** `Ansible/group_vars/proxmox/certificate.yaml` (inline comments)

## Support Resources

- **Let's Encrypt Documentation:** https://letsencrypt.org/docs/
- **Cloudflare API Docs:** https://api.cloudflare.com/
- **Proxmox ACME Guide:** https://pve.proxmox.com/wiki/Certificate_Management
- **acme.sh DNS Providers:** https://github.com/acmesh-official/acme.sh/wiki/dnsapi
- **Ansible Documentation:** https://docs.ansible.com/

---

**You're all set!** The infrastructure is ready. Just add your Cloudflare API token and enable ACME when ready.
