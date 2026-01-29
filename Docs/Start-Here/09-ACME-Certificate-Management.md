# ACME Certificate Management for Proxmox

## Overview

This guide explains how to set up automatic ACME (Let's Encrypt) certificate management for Proxmox VE using the `proxmox-certs` Ansible role with the infrastructure automation provided in this repository.

## Prerequisites

- Proxmox VE 7.0+ cluster deployed using the `setup-proxmox-nodes.yaml` playbook
- A registered domain (this guide uses `sinlessgames.com`)
- DNS provider API access (we use Cloudflare, but Route53, DigitalOcean, OVH, and others are supported)
- Ansible 2.9+ with cryptography and openssl modules installed

## Architecture

The certificate management system uses a two-tier approach:

1. **Self-signed certificates (default)** - Generated immediately during node provisioning
2. **ACME-managed certificates (optional)** - Automatically obtained from Let's Encrypt and renewed

The `proxmox-ha-ui` role provides an HA load balancer that can use either certificate type. Switching between them requires only changing the certificate source in the configuration.

## Step-by-Step Setup

### Step 1: Obtain DNS API Credentials

#### Cloudflare (Recommended)

1. Log in to your Cloudflare dashboard
2. Go to **Profile** → **API Tokens**
3. Click **Create Token**
4. Use template: **Edit Zone DNS**
5. Grant permissions:
   - Zone DNS: Edit
   - Zone: Include specific zone (select your domain)
6. Copy the generated API token
7. Store securely in your vault

Example token format: `8afbe6dea4241241e6e1d6c3d66f2e3ax`

**For Ansible:** Format as `CF_Token=8afbe6dea4241241e6e1d6c3d66f2e3ax`

#### Route53 (AWS)

Create IAM user with policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetChange",
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": ["arn:aws:route53:::hostedzone/YOUR_ZONE_ID"]
    }
  ]
}
```

**For Ansible:** `AWS_ACCESS_KEY_ID=xxx&AWS_SECRET_ACCESS_KEY=yyy`

#### DigitalOcean

1. Create API token in DigitalOcean dashboard
2. Grant: `write` permission for DNS records

**For Ansible:** `DO_AUTH_TOKEN=xxx`

### Step 2: Configure Vault with DNS Credentials

Edit the vault file:
```bash
ansible-vault edit Ansible/group_vars/proxmox/vault-certs.yaml
```

Add your DNS provider credentials (example with Cloudflare):
```yaml
vault_cloudflare_dns_token: "CF_Token=8afbe6dea4241241e6e1d6c3d66f2e3ax"
```

Encrypt the vault file with your vault password:
```bash
ansible-vault encrypt Ansible/group_vars/proxmox/vault-certs.yaml --vault-password-file ~/.vault_pass
```

### Step 3: Update Certificate Configuration

Edit `Ansible/group_vars/proxmox/certificate.yaml`:

```yaml
# Enable ACME
proxmox_acme_enabled: true

# Use Let's Encrypt (set to true for staging, false for production)
proxmox_acme_provider_staging: false

# Your domain
proxmox_acme_domains:
  - "proxmox.sinlessgames.com"
  - "*.sinlessgames.com"
  - "sinlessgames.com"

# Email for Let's Encrypt notifications
proxmox_acme_email: "admin@sinlessgames.com"

# DNS provider (cloudflare, route53, digitalocean, ovh, etc.)
proxmox_acme_dns_api: "cloudflare"
proxmox_acme_plugin_id: "dns_cloudflare"

# Use vault for credentials
proxmox_acme_dns_api_data: "{{ vault_cloudflare_dns_token }}"
```

### Step 4: Set Proxmox Root Password (for ACME API configuration)

The role needs to authenticate with Proxmox API to configure ACME accounts and plugins. Add to your command:

```bash
ansible-playbook Ansible/playbooks/setup-proxmox-nodes.yaml \
  --tags proxmox,certs,certificates \
  --ask-vault-pass \
  -e "proxmox_acme_password=YOUR_PROXMOX_ROOT_PASSWORD"
```

Or add to your vault:
```yaml
vault_proxmox_root_password: "YOUR_PASSWORD"
```

And reference in certificate.yaml:
```yaml
proxmox_acme_password: "{{ vault_proxmox_root_password }}"
```

### Step 5: Deploy the Certificate Role

Run the playbook with certificate tags:

```bash
ansible-playbook Ansible/playbooks/setup-proxmox-nodes.yaml \
  --tags proxmox,certs,certificates \
  --ask-vault-pass
```

The role will:
1. Create backup of existing certificates
2. Configure ACME account in Proxmox
3. Register DNS validation plugin
4. Set up certificate auto-renewal

### Step 6: Verify ACME Configuration in Proxmox UI (Optional)

Navigate to Proxmox UI → **Datacenter** → **ACME** to view:

- **Accounts** tab:
  - Account Name: `default`
  - Email: `admin@sinlessgames.com`
  - Directory: Let's Encrypt (Production or Staging)

- **Plugins** tab:
  - Plugin ID: `dns_cloudflare`
  - Type: DNS
  - DNS API: `cloudflare`
  - API Data: `CF_Token=...` (from vault)

- **Certificate** tab (per node):
  - Domain: `proxmox.sinlessgames.com`
  - UID: Maps to node identity
  - Status: Ready to request

## Request Certificates via Proxmox UI

Once ACME is configured:

1. Go to **Node** (e.g., pve-01) → **Certificates** → **Proxmox VE Certificate**
2. Click **Order Certificate Now**
3. Proxmox will:
   - Create CSR with domains from `proxmox_acme_domains`
   - Request certificate from Let's Encrypt
   - Validate ownership via DNS (automatic)
   - Install certificate on the node
   - Restart pveproxy and pvedaemon

The certificate appears in:
- `/etc/pve/nodes/pve-01/pve-ssl.pem` (combined cert+key)
- `/etc/pve/nodes/pve-01/pve-ssl.key` (separate key, if supported)

## Certificate Renewal

Proxmox automatically renews certificates:
- Default renewal window: 30 days before expiration
- Renewal method: Automatic via ACME
- Failure notifications sent to `proxmox_acme_email`

To check certificate status:
```bash
openssl x509 -noout -text -in /etc/pve/nodes/pve-01/pve-ssl.pem | grep -A2 "Subject:"
openssl x509 -noout -enddate -in /etc/pve/nodes/pve-01/pve-ssl.pem
```

To manually renew:
1. Proxmox UI → Node → Certificates → **Renew Certificate Now**
2. Or via CLI:
```bash
proxmox-acme update --cert default --renew
```

## Troubleshooting

### ACME Account Registration Fails

**Error:** "ACME account not found" or "Invalid directory"

**Solution:**
1. Verify `proxmox_acme_directory` is set correctly for your provider
2. Check Proxmox logs: `journalctl -u pvedaemon -n 50`
3. Verify API authentication: `proxmox_acme_password` must be correct root password

### DNS Validation Fails

**Error:** "DNS challenge failed" or "Validation timeout"

**Symptoms:**
- Certificate request stuck in pending state
- DNS records not created

**Solution:**
1. Verify DNS API credentials in vault-certs.yaml
2. Test DNS access:
   ```bash
   # For Cloudflare
   curl -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```
3. Check Proxmox logs for DNS API errors:
   ```bash
   tail -f /var/log/pveproxy/access.log
   ```

### Certificate Not Installing

**Error:** "Certificate installation failed"

**Solution:**
1. Verify certificate path permissions: `/etc/pve/nodes/pve-01/`
2. Check pveproxy can read the certificate:
   ```bash
   ls -la /etc/pve/nodes/pve-01/pve-ssl.pem
   ```
3. Restart services manually:
   ```bash
   systemctl restart pveproxy pvedaemon
   ```

### Staging vs Production

For testing without Let's Encrypt rate limits:

```yaml
proxmox_acme_provider_staging: true
proxmox_acme_directory: "{{ proxmox_acme_directory_letsencrypt_staging }}"
```

Staging certificates will show browser warnings but validate ACME setup.

Switch to production once testing succeeds:
```yaml
proxmox_acme_provider_staging: false
```

## DNS Providers Reference

| Provider | Plugin ID | DNS API | Example Credentials |
|----------|-----------|---------|----------------------|
| Cloudflare | `dns_cloudflare` | `cloudflare` | `CF_Token=xxx` |
| Route53 (AWS) | `dns_route53` | `route53` | `AWS_ACCESS_KEY_ID=xxx&AWS_SECRET_ACCESS_KEY=yyy` |
| DigitalOcean | `dns_digitalocean` | `digitalocean` | `DO_AUTH_TOKEN=xxx` |
| OVH | `dns_ovh` | `ovh` | `OVH_ENDPOINT=xxx&OVH_APPLICATION_KEY=yyy&OVH_APPLICATION_SECRET=zzz&OVH_CONSUMER_KEY=www` |
| Linode | `dns_linode` | `linode` | `LINODE_TOKEN=xxx` |
| Godaddy | `dns_godaddy` | `godaddy` | `GODADDY_API_KEY=xxx&GODADDY_API_SECRET=yyy` |

See [acme.sh DNS provider documentation](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) for complete list.

## Configuration Summary

| Setting | Value | Purpose |
|---------|-------|---------|
| `proxmox_cert_source` | `"self-signed"` or `"acme"` | Certificate source type |
| `proxmox_acme_enabled` | `true` or `false` | Enable ACME management |
| `proxmox_acme_provider` | `"letsencrypt"` | ACME provider selection |
| `proxmox_acme_provider_staging` | `true` or `false` | Use staging (testing) server |
| `proxmox_acme_email` | `"admin@sinlessgames.com"` | Contact email for certificates |
| `proxmox_acme_domains` | List | Domains to include in certificate |
| `proxmox_acme_dns_api` | `"cloudflare"` | DNS validation provider |
| `proxmox_acme_dns_api_data` | `"CF_Token=..."` | DNS provider credentials (vault) |
| `proxmox_cert_renewal_threshold` | `30` | Days before expiration to renew |
| `proxmox_cert_backup` | `true` | Backup old certificates |
| `proxmox_cert_backup_retention` | `5` | Number of backups to keep |

## Advanced Configuration

### Custom Certificate Renewal Schedule

Proxmox checks for renewal every 12 hours by default. Modify via cron:

```bash
crontab -e
```

Add:
```cron
# Proxmox ACME certificate renewal check (daily at 2 AM)
0 2 * * * /usr/local/bin/proxmox-acme renew-check
```

### Multiple Domains with Wildcards

Include main domain and wildcard in SANs:
```yaml
proxmox_acme_domains:
  - "proxmox.sinlessgames.com"     # Main Proxmox domain
  - "*.sinlessgames.com"            # Wildcard for other services
  - "sinlessgames.com"              # Root domain
  - "api.sinlessgames.com"          # Additional services
  - "app.sinlessgames.com"
```

### Fallback to Self-Signed

If ACME fails, system automatically uses self-signed certificates. To manually revert:

```yaml
proxmox_cert_source: "self-signed"
proxmox_acme_enabled: false
```

Then re-run the certificate role.

## Related Documentation

- [Proxmox ACME Configuration Guide](https://pve.proxmox.com/wiki/Certificate_Management)
- [acme.sh DNS Validation Providers](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)
- [Let's Encrypt Rate Limiting](https://letsencrypt.org/docs/rate-limits/)
- [Repository: Proxmox HA UI Role](../Ansible/roles/proxmox-ha-ui/README.md)
- [Repository: Proxmox Certificate Role](../Ansible/roles/proxmox-certs/README.md)

## Support

For issues or questions:
1. Check `/var/log/pveproxy/access.log` on affected Proxmox node
2. Run certificate role with verbose flag: `-vvv`
3. Review ACME account status in Proxmox UI → Datacenter → ACME
