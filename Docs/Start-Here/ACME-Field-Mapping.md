# Proxmox ACME Field Reference - Ansible to UI Mapping

This document shows how Ansible variables automatically map to Proxmox ACME configuration fields, so you don't have to manually fill them out in the UI.

## Quick Reference Map

### Proxmox UI → Datacenter → ACME → Accounts Tab

When running `ansible-playbook` with certificate role and `proxmox_acme_enabled: true`:

```
┌─────────────────────────────────────────────────────────────┐
│  Proxmox UI Field                 Ansible Variable          │
├─────────────────────────────────────────────────────────────┤
│  Account Name                  ← proxmox_acme_account_name   │
│                                   (value: "default")         │
├─────────────────────────────────────────────────────────────┤
│  E-Mail                        ← proxmox_acme_email          │
│                                   (value: "admin@sinless...")│
├─────────────────────────────────────────────────────────────┤
│  ACME Directory                ← proxmox_acme_directory      │
│                                   (value: Let's Encrypt URL) │
└─────────────────────────────────────────────────────────────┘
```

**Location in file:** `Ansible/group_vars/proxmox/certificate.yaml` (lines 63-120)

### Proxmox UI → Datacenter → ACME → Plugins Tab

```
┌──────────────────────────────────────────────────────────────┐
│  Proxmox UI Field                  Ansible Variable          │
├──────────────────────────────────────────────────────────────┤
│  Plugin ID                     ← proxmox_acme_plugin_id       │
│                                   (value: "dns_cloudflare")   │
├──────────────────────────────────────────────────────────────┤
│  Type                          ← proxmox_acme_plugin_type     │
│                                   (value: "dns")              │
├──────────────────────────────────────────────────────────────┤
│  DNS API                       ← proxmox_acme_dns_api         │
│                                   (value: "cloudflare")       │
├──────────────────────────────────────────────────────────────┤
│  API Data                      ← proxmox_acme_dns_api_data    │
│                                   (value from vault:          │
│                                   "CF_Token=xxxx...")        │
└──────────────────────────────────────────────────────────────┘
```

**Location in file:** `Ansible/group_vars/proxmox/certificate.yaml` (lines 110-120)

### Proxmox UI → Node → Certificates → Proxmox VE Certificate

When requesting certificate via UI "Order Certificate Now" button:

```
┌────────────────────────────────────────────────────────────────┐
│  Proxmox Certificate Field             Ansible Variable        │
├────────────────────────────────────────────────────────────────┤
│  Common Name (CN)                  ← proxmox_cert_cn           │
│                                        (value: "proxmox.si...") │
├────────────────────────────────────────────────────────────────┤
│  Subject Alternative Names (SANs)  ← proxmox_cert_san          │
│                                        (value: list of         │
│                                         domains)                │
├────────────────────────────────────────────────────────────────┤
│  Challenge Type                    ← proxmox_acme_challenge_... │
│                                        (value: "dns-01")        │
└────────────────────────────────────────────────────────────────┘
```

**Location in file:** `Ansible/group_vars/proxmox/certificate.yaml` (lines 32-50)

## Configuration File Structure

### Location
```
Ansible/
├── group_vars/
│   └── proxmox/
│       ├── certificate.yaml              ← Main ACME config
│       └── vault-certs.yaml              ← Encrypted secrets
└── roles/
    └── proxmox-certs/
        ├── tasks/main.yaml               ← ACME setup tasks
        └── README.md                     ← Detailed docs
```

### Inheritance Chain

1. **certificate.yaml** (plain-text configuration)
   - Ansible variables defined here
   - Maps to Proxmox UI fields
   - Includes vault references: `{{ vault_cloudflare_dns_token }}`

2. **vault-certs.yaml** (encrypted secrets)
   - Contains sensitive API tokens
   - Encrypted with `ansible-vault encrypt`
   - Referenced via jinja2 variable: `vault_cloudflare_dns_token`

3. **Proxmox** (running configuration)
   - Reads variables during playbook execution
   - Uses Ansible API to populate Proxmox UI fields
   - Stores in Proxmox configuration files

Example flow:
```
Ansible variable               Vault variable              Proxmox stored as
───────────────────────────────────────────────────────────────────────
proxmox_acme_email             (not sensitive)             /etc/pve/acme/accounts/...
proxmox_acme_dns_api           (not sensitive)             /etc/pve/acme/plugins/...
proxmox_acme_dns_api_data ──┬──vault_cloudflare_dns...──→ /etc/pve/acme/plugins/...
                            │
                    Decrypted by ansible-vault
```

## Editing Workflow

### To add new ACME provider:

1. **Edit certificate.yaml:**
   ```yaml
   proxmox_acme_dns_api: "route53"          # Change DNS provider
   proxmox_acme_plugin_id: "dns_route53"    # Update plugin ID
   ```

2. **Update vault-certs.yaml:**
   ```bash
   ansible-vault edit Ansible/group_vars/proxmox/vault-certs.yaml
   ```
   
   Add credentials:
   ```yaml
   vault_route53_credentials: "AWS_ACCESS_KEY_ID=xxx&AWS_SECRET_ACCESS_KEY=yyy"
   ```

3. **Reference in certificate.yaml:**
   ```yaml
   proxmox_acme_dns_api_data: "{{ vault_route53_credentials }}"
   ```

4. **Run playbook:**
   ```bash
   ansible-playbook Ansible/playbooks/setup-proxmox-nodes.yaml \
     --tags proxmox,certs \
     --ask-vault-pass
   ```

### To switch from staging to production:

Edit certificate.yaml:
```yaml
# Line ~82-83
proxmox_acme_provider_staging: false  # Change from true to false
```

The `proxmox_acme_directory` variable will automatically switch to production Let's Encrypt URL.

## Variable Dependency Graph

```
certificate.yaml:
├── proxmox_acme_enabled
│   ├── proxmox_acme_account_name
│   ├── proxmox_acme_email
│   ├── proxmox_acme_directory
│   │   ├── proxmox_acme_provider
│   │   └── proxmox_acme_provider_staging
│   │       ├── proxmox_acme_directory_letsencrypt_prod
│   │       └── proxmox_acme_directory_letsencrypt_staging
│   ├── proxmox_acme_challenge_type
│   ├── proxmox_acme_plugin_id
│   ├── proxmox_acme_plugin_type
│   ├── proxmox_acme_dns_api
│   ├── proxmox_acme_dns_api_data
│   │   └── vault_cloudflare_dns_token (from vault-certs.yaml)
│   └── proxmox_acme_domains
└── (other certificate variables)
```

## Example: Complete Setup for Different Providers

### Cloudflare (Current Default)
```yaml
# certificate.yaml
proxmox_acme_enabled: true
proxmox_acme_dns_api: "cloudflare"
proxmox_acme_plugin_id: "dns_cloudflare"
proxmox_acme_dns_api_data: "{{ vault_cloudflare_dns_token }}"

# vault-certs.yaml
vault_cloudflare_dns_token: "CF_Token=YOUR_TOKEN_HERE"
```

### Route53 (AWS)
```yaml
# certificate.yaml
proxmox_acme_enabled: true
proxmox_acme_dns_api: "route53"
proxmox_acme_plugin_id: "dns_route53"
proxmox_acme_dns_api_data: "{{ vault_route53_credentials }}"

# vault-certs.yaml
vault_route53_credentials: "AWS_ACCESS_KEY_ID=xxx&AWS_SECRET_ACCESS_KEY=yyy"
```

### DigitalOcean
```yaml
# certificate.yaml
proxmox_acme_enabled: true
proxmox_acme_dns_api: "digitalocean"
proxmox_acme_plugin_id: "dns_digitalocean"
proxmox_acme_dns_api_data: "{{ vault_digitalocean_token }}"

# vault-certs.yaml
vault_digitalocean_token: "DO_AUTH_TOKEN=YOUR_TOKEN_HERE"
```

## Proxmox UI Screenshot → Variable Mapping

### Register Account Dialog
```
┌──────────────────────────────────────────────────┐
│ Account Name: [default...................]        │← proxmox_acme_account_name
│                                                   │
│ E-Mail: [admin@sinlessgames.com.............]   │← proxmox_acme_email
│                                                   │
│ ACME Directory:                                   │
│ [https://acme-v02.api.letsencrypt.org/...]     │← proxmox_acme_directory
│                                                   │
│          [Register]                               │
└──────────────────────────────────────────────────┘
```

**These fields are auto-filled when running the Ansible playbook with `proxmox_acme_enabled: true`**

### Add ACME DNS Plugin Dialog
```
┌──────────────────────────────────────────────────┐
│ Plugin ID: [dns_cloudflare................]       │← proxmox_acme_plugin_id
│                                                   │
│ Validation Delay: [30...................]         │ (optional)
│                                                   │
│ DNS API:                                          │
│ [cloudflare................]                     │← proxmox_acme_dns_api
│                                                   │
│ API Data:                                         │
│ [CF_Token=xxxxxxxxxxxxx]                         │← proxmox_acme_dns_api_data
│                                                   │
│          [Add]                                    │
└──────────────────────────────────────────────────┘
```

**These fields are also auto-filled by the Ansible role during certificate configuration.**

## Validation Checklist

Before running playbook, verify in certificate.yaml:

- [ ] `proxmox_acme_enabled: true` (line 59)
- [ ] `proxmox_acme_email` set to your email (line 84)
- [ ] `proxmox_acme_provider` is "letsencrypt" or preferred provider (line 81)
- [ ] `proxmox_acme_provider_staging` correct (false for production, true for testing)
- [ ] `proxmox_acme_dns_api` matches your provider (line 105)
- [ ] `proxmox_acme_plugin_id` correct (line 103)
- [ ] `proxmox_acme_dns_api_data` references correct vault variable (line 115)

Verify in vault-certs.yaml:

- [ ] Encrypted with `ansible-vault encrypt` (check for `$ANSIBLE_VAULT`)
- [ ] API token added for your DNS provider (line ~10)
- [ ] Token format correct for provider (e.g., `CF_Token=...` for Cloudflare)

## Troubleshooting Variable Mapping Issues

### Problem: UI shows empty fields
**Cause:** Variables not interpolated during playbook run
**Solution:** 
1. Verify `proxmox_acme_password` is set (needed for API auth)
2. Check task output: `... Configure ACME in Proxmox ...`
3. Review `/var/log/pveproxy/access.log` on Proxmox node

### Problem: DNS validation fails
**Cause:** `proxmox_acme_dns_api_data` vault reference not working
**Solution:**
1. Run playbook with `--ask-vault-pass`
2. Verify vault-certs.yaml decrypts: `ansible-vault view Ansible/group_vars/proxmox/vault-certs.yaml`
3. Check token format matches provider

### Problem: Certificate doesn't request from UI
**Cause:** ACME directory URL invalid or plugin not registered
**Solution:**
1. Verify `proxmox_acme_directory` in Proxmox UI (Datacenter > ACME > Accounts)
2. Check plugin shows in Datacenter > ACME > Plugins
3. Manually re-register: Datacenter > ACME > Accounts > "Register Account"

## Related Files

- Main configuration: [Ansible/group_vars/proxmox/certificate.yaml](../../Ansible/group_vars/proxmox/certificate.yaml)
- Secrets vault: [Ansible/group_vars/proxmox/vault-certs.yaml](../../Ansible/group_vars/proxmox/vault-certs.yaml)
- Certificate role: [Ansible/roles/proxmox-certs/](../../Ansible/roles/proxmox-certs/)
- Setup guide: [Docs/Start-Here/09-ACME-Certificate-Management.md](09-ACME-Certificate-Management.md)
- Playbook: [Ansible/playbooks/setup-proxmox-nodes.yaml](../../Ansible/playbooks/setup-proxmox-nodes.yaml)

## Next Steps

1. **Enable ACME:** Set `proxmox_acme_enabled: true` in certificate.yaml
2. **Add credentials:** Add API token to vault-certs.yaml
3. **Run playbook:** Execute certificate role with vault password
4. **Verify UI:** Check Proxmox UI for auto-populated ACME fields
5. **Request certificate:** Use Proxmox UI → Node → Certificates → "Order Certificate Now"
