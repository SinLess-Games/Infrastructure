# ACME Certificate Management - Architecture & Flow Diagrams

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        PROXMOX HA INFRASTRUCTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  EXTERNAL                                                                     │
│  ┌──────────────────┐                                                        │
│  │  Let's Encrypt   │  ◄──── ACME Certificate Request                       │
│  │  (letsencrypt.   │  ──────────────────────────────────────┐              │
│  │  org)            │                                        │              │
│  └──────────────────┘                                        │              │
│         ▲                                                     │              │
│         │ DNS Challenge                                      │              │
│         │ CF_Token=xxxxx                                    │              │
│         │                                                   │              │
│  ┌──────┴──────────────┐                                   │              │
│  │  Cloudflare DNS     │  ◄────────────────────────────────┘              │
│  │  API                │                                                   │
│  │  (dns validation)   │                                                   │
│  └─────────────────────┘                                                   │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────      │
│                                                                             │
│  ANSIBLE (Your Machine)                                                    │
│  ┌────────────────────────────────────────────────────┐                   │
│  │ certificate.yaml (Pre-configured)                  │                   │
│  ├────────────────────────────────────────────────────┤                   │
│  │ • proxmox_acme_enabled: true                       │                   │
│  │ • proxmox_acme_email: admin@sinlessgames.com       │                   │
│  │ • proxmox_acme_dns_api: cloudflare                 │                   │
│  │ • proxmox_acme_domains: [proxmox.sinlessgames...] │                   │
│  └────────┬─────────────────────────────────────────┘                   │
│           │                                                               │
│           │ References vault                                             │
│           ▼                                                               │
│  ┌────────────────────────────────────────────────────┐                   │
│  │ vault-certs.yaml (Encrypted)                       │                   │
│  ├────────────────────────────────────────────────────┤                   │
│  │ vault_cloudflare_dns_token: CF_Token=xxxxx        │                   │
│  └────────┬─────────────────────────────────────────┘                   │
│           │                                                               │
│           │ ansible-playbook setup-proxmox-nodes.yaml                   │
│           │ --tags proxmox,certs --ask-vault-pass                      │
│           │                                                               │
│           ▼                                                               │
│  ┌────────────────────────────────────────────────────┐                   │
│  │ proxmox-certs Ansible Role                         │                   │
│  │ (tasks/main.yaml)                                  │                   │
│  │                                                    │                   │
│  │ 1. Register ACME account in Proxmox API           │                   │
│  │ 2. Configure DNS plugin with Cloudflare token     │                   │
│  │ 3. Setup certificate renewal automation           │                   │
│  └────────┬─────────────────────────────────────────┘                   │
│           │ HTTPS POST /api2/json/nodes/X/certificates/acme/...         │
│           │                                                               │
│  ────────────────────────────────────────────────────────────────────      │
│                                                                             │
│  PROXMOX CLUSTER (pve-01 through pve-05)                                  │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │ Each Node: pve-01, pve-02, pve-03, pve-04, pve-05               │   │
│  ├───────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │  Ansible Role Deploys:                                            │   │
│  │  ─────────────────────                                            │   │
│  │  ✓ /etc/pve/acme/accounts/default/                              │   │
│  │    └─ Contains: ACME account registration data                   │   │
│  │                                                                     │   │
│  │  ✓ /etc/pve/acme/plugins/dns_cloudflare/                         │   │
│  │    └─ Contains: Cloudflare DNS API credentials                   │   │
│  │                                                                     │   │
│  │  ✓ /etc/pve/nodes/pve-01/pve-ssl.pem (certificate)              │   │
│  │    └─ Self-signed initially, replaced with ACME when requested   │   │
│  │                                                                     │   │
│  │  ✓ Certificate renewal automation                                 │   │
│  │    └─ Runs every 12 hours, renews 30 days before expiration     │   │
│  │                                                                     │   │
│  └───────────────────────────────────────────────────────────────────┘   │
│           ▲                                                                 │
│           │ (Now able to request ACME certificates)                       │
│           │                                                                 │
│           └─ ACME certificate request via:                                │
│              1. Proxmox UI: Node > Certificates > Order Certificate Now   │
│              2. Or: CLI: proxmox-acme update --cert default --renew      │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────      │
│                                                                             │
│  HA UI LOAD BALANCER (pve-01)                                             │
│  ┌────────────────────────────────────────────────────┐                   │
│  │ Keepalived VIP: 10.10.10.14                        │                   │
│  │                                                    │                   │
│  │ ┌──────────────────────────────────────────────┐  │                   │
│  │ │ HAProxy 3.0.11 (HTTPS Port 443)              │  │                   │
│  │ │                                               │  │                   │
│  │ │ • Certificate: /etc/pve/nodes/pve-01/...    │  │                   │
│  │ │ • Backend servers: pve-01:8006 ... pve-05  │  │                   │
│  │ │ • Health checks: GET /api2/json/version    │  │                   │
│  │ │ • Load balancing: Round-robin               │  │                   │
│  │ └──────────────────────────────────────────────┘  │                   │
│  └────────────────────────────────────────────────────┘                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Configuration Flow: Ansible to Proxmox UI

```
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 1: Ansible Configuration                                       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  certificate.yaml                                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ proxmox_acme_enabled: true                                  │   │
│  │ proxmox_acme_email: admin@sinlessgames.com                  │   │
│  │ proxmox_acme_account_name: "default"                        │   │
│  │ proxmox_acme_directory: https://acme-v02.api.letsencrypt... │   │
│  │ proxmox_acme_dns_api: "cloudflare"                          │   │
│  │ proxmox_acme_plugin_id: "dns_cloudflare"                    │   │
│  │ proxmox_acme_dns_api_data: vault_cloudflare_dns_token       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│           │                                                          │
│           │ (Vault decrypted during playbook)                       │
│           ▼                                                          │
│  vault-certs.yaml (Encrypted)                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ vault_cloudflare_dns_token: "CF_Token=abcd1234efgh5678"    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│           │                                                          │
│           │ All variables ready for Ansible tasks                   │
│           ▼                                                          │
│  proxmox-certs role / tasks/main.yaml                               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Task 1: Register ACME account                               │   │
│  │   URI: POST /api2/json/nodes/pve-01/certificates/acme/...  │   │
│  │   Body:                                                      │   │
│  │   {                                                          │   │
│  │     "directory": "{{ proxmox_acme_directory }}",            │   │
│  │     "email": "{{ proxmox_acme_email }}",                    │   │
│  │     "tos": "1"                                               │   │
│  │   }                                                          │   │
│  │                                                             │   │
│  │ Task 2: Configure ACME plugin                               │   │
│  │   URI: POST /api2/json/nodes/pve-01/certificates/acme/...  │   │
│  │   Body:                                                      │   │
│  │   {                                                          │   │
│  │     "type": "dns",                                          │   │
│  │     "api": "{{ proxmox_acme_dns_api }}",                    │   │
│  │     "data": "{{ proxmox_acme_dns_api_data }}"              │   │
│  │   }                                                          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
         │
         │ API calls to Proxmox
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 2: Proxmox ACME Configuration (automatic)                      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  On Proxmox Node (pve-01):                                           │
│                                                                       │
│  Storage Layer:                                                       │
│  ├─ /etc/pve/acme/accounts/default/                                 │
│  │  └─ account.json                                                  │
│  │     {                                                             │
│  │       "email": "admin@sinlessgames.com",                          │
│  │       "directory": "https://acme-v02.api.letsencrypt.org/...",  │
│  │       ...                                                         │
│  │     }                                                             │
│  │                                                                   │
│  └─ /etc/pve/acme/plugins/dns_cloudflare/                           │
│     └─ plugin.json                                                   │
│        {                                                             │
│          "type": "dns",                                             │
│          "api": "cloudflare",                                        │
│          "data": "CF_Token=abcd1234efgh5678"                        │
│        }                                                             │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
         │
         │ Configuration stored in Proxmox
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 3: Proxmox UI Auto-Populated                                   │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Datacenter → ACME → Accounts Tab:                                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Account Name: default                  ← proxmox_acme...   │   │
│  │ Email: admin@sinlessgames.com         ← proxmox_acme_email │   │
│  │ Status: Ready                                               │   │
│  │ ACME Directory: https://acme-v02...   ← proxmox_acme...    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  Datacenter → ACME → Plugins Tab:                                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Plugin ID: dns_cloudflare             ← proxmox_acme...    │   │
│  │ Type: DNS                             ← proxmox_acme...    │   │
│  │ DNS API: cloudflare                   ← proxmox_acme_dns...│   │
│  │ API Data: CF_Token=abcd...            ← vault credential   │   │
│  │ Status: Ready                                               │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  Node (pve-01) → Certificates Tab:                                   │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Proxmox VE Certificate                                      │   │
│  │ ├─ Status: Self-signed (can now request ACME)             │   │
│  │ ├─ Issuer: Self (or Let's Encrypt if requested)            │   │
│  │ ├─ Common Name: proxmox.sinlessgames.com                   │   │
│  │ ├─ [Order Certificate Now] ← Now functional!               │   │
│  │ └─ [Renew Certificate]                                     │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
         │
         │ User clicks "Order Certificate Now"
         ▼
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 4: Certificate Request & Installation                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Proxmox → Let's Encrypt:                                            │
│  1. Create CSR with domains (auto-populated from config)             │
│  2. Request new certificate from Let's Encrypt                       │
│  3. Create DNS challenge: _acme-challenge.proxmox.sinlessgames...   │
│  4. Call Cloudflare API with CF_Token to create DNS record          │
│  5. Let's Encrypt validates DNS challenge                           │
│  6. Issue certificate: proxmox.sinlessgames.com (+ SANs)            │
│  7. Install at: /etc/pve/nodes/pve-01/pve-ssl.pem                  │
│  8. Restart: pveproxy, pvedaemon                                     │
│  9. Send confirmation email to: admin@sinlessgames.com              │
│                                                                       │
│  Result in Proxmox UI:                                               │
│  Node → Certificates:                                                │
│  ├─ Issuer: Let's Encrypt                                           │
│  ├─ Expires: (90 days from now)                                     │
│  └─ Status: Active                                                   │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

## Certificate Lifecycle

```
TIME →

Day 0: Certificate Installed
      │
      │ Certificate Valid for 90 days
      │ Status: Active in pveproxy/pvedaemon
      │
      ├─────────────────────────────────────────────────┐
      │                                                 │
Day 30: RENEWAL PHASE BEGINS                           │
      │ ├─ Proxmox renewal check (every 12 hours)     │
      │ ├─ 30-day threshold reached (config setting)   │
      │ ├─ Renewal eligible                             │
      │ │                                                │
      │ └─ Let's Encrypt renewal (automatic):           │
      │    ├─ Request new certificate                   │
      │    ├─ DNS validation via Cloudflare             │
      │    ├─ Issue new certificate                     │
      │    └─ Install automatically                     │
      │                                                 │
Day 60: Certificate refreshed                          │
      │ ├─ New certificate active                      │
      │ ├─ Old certificate backed up (pve-ssl.pem.xxx) │
      │ ├─ Confirmation email sent                     │
      │ └─ Status: Active, 30 days remaining            │
      │                                                 │
Day 90: Original certificate would expire              │
      │ ├─ But already replaced on Day 60              │
      │ ├─ No service interruption                      │
      │ └─ Zero-downtime renewal ✓                     │
      │                                                 │
      │ (Cycle repeats)                                 │
      │                                                 │
      └──────────────────────────────────────────────┘

Configuration:
- proxmox_cert_renewal_threshold: 30 (days)
- proxmox_cert_validity_days: 365 (for self-signed)
- proxmox_cert_backup: true
- proxmox_cert_backup_retention: 5 (versions)
- proxmox_cert_auto_renew: true
```

## DNS Validation Flow (Let's Encrypt ↔ Cloudflare)

```
Proxmox                    Let's Encrypt                  Cloudflare
   │                            │                             │
   │─── Certificate Request ────>│                             │
   │                            │                             │
   │                            │─── Challenge: DNS-01 ──>│
   │                            │                          │
   │<──────── Wait for Validation ──────────────────────────┤
   │                                                         │
   │─────── Cloudflare API Call (CF_Token) ───────────────>│
   │        POST /client/v4/zones/.../dns_records          │
   │        Create: _acme-challenge.proxmox.sinlessgames.  │
   │                                                         │
   │                                                        │
   │                            │<─ Validate DNS Record ────│
   │                            │                          │
   │                            │─── DNS Valid ───────────>│
   │                                                        │
   │<────── Issue Certificate ──────────────────────────────│
   │        CN: proxmox.sinlessgames.com                   │
   │        SAN: *.sinlessgames.com, sinlessgames.com      │
   │        Valid for: 90 days                              │
   │                                                         │
   │─────── Cleanup DNS Record ───────────────────────────>│
   │        DELETE _acme-challenge.proxmox.sinlessgames...  │
   │                                                         │
   ├─ Store certificate: /etc/pve/nodes/pve-01/pve-ssl.pem
   ├─ Restart services: pveproxy, pvedaemon
   └─ Send email: admin@sinlessgames.com
       "Certificate installed successfully"
```

## Multi-Node Scenario

```
Ansible Playbook with --tags proxmox,certs

├─ Configure pve-01 (Master node, automatic first run)
│  ├─ Register ACME account: /etc/pve/acme/accounts/default/
│  ├─ Configure plugin: /etc/pve/acme/plugins/dns_cloudflare/
│  ├─ Proxmox UI shows: Ready to request
│  └─ Certificate not yet issued (manual request from UI)
│
├─ Configure pve-02
│  ├─ Register ACME account: (skipped, uses shared account)
│  ├─ Configure plugin: (copies from pve-01)
│  └─ Can also request certificates for *.sinlessgames.com
│
├─ Configure pve-03
│  ├─ Register ACME account: (skipped)
│  ├─ Configure plugin: (copies from pve-01)
│  └─ Shares same DNS credentials
│
├─ Configure pve-04
│  └─ Same pattern...
│
└─ Configure pve-05
   └─ Same pattern...

Result:
All 5 nodes configured with:
✓ Same ACME account (default)
✓ Same DNS plugin (dns_cloudflare)
✓ Same Cloudflare credentials
✓ Can independently request certificates
✓ Auto-renewal happens on each node
✓ Zero-downtime certificate rotation
```

## Integration with HA UI Load Balancer

```
HTTPS Traffic to Proxmox UI
│
└──> Load Balancer (HAProxy on pve-01 VIP: 10.10.10.14)
     │
     ├──> Certificate: /etc/pve/nodes/pve-01/pve-ssl.pem
     │    (Self-signed initially, ACME certificate after request)
     │
     └──> Backend Servers
         ├──> pve-01:8006 (Self-signed)
         ├──> pve-02:8006 (Self-signed or ACME)
         ├──> pve-03:8006 (Self-signed or ACME)
         ├──> pve-04:8006 (Self-signed or ACME)
         └──> pve-05:8006 (Self-signed or ACME)

Load Balancer Behavior:
- Accepts traffic on HTTPS 443
- Decrypts with frontend certificate (pve-01 pve-ssl.pem)
- Connects to backends with SSL (accepts any valid cert)
- Health checks: GET /api2/json/version (accepts 200, 401)
- Session stickiness: Cookie-based (SERVERID)
- Certificate renewal: Restarts HAProxy when pve-01 cert changes

Result:
Users access: https://proxmox.sinlessgames.com (DNS A record → 10.10.10.14)
├─ Single certificate for domain
├─ Automatic renewal
├─ No downtime during renewal
├─ Load balanced across 5 nodes
└─ Fully automated via Ansible + ACME
```

---

**Visual Diagram Notes:**
- Green ✓ = Automatically configured by Ansible
- Blue → = Information/credential flow
- Orange ⚠️ = Manual action required
- Gray □ = Storage/file locations
