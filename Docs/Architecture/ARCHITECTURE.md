# Infrastructure Architecture

```text
Document: ARCHITECTURE.md
Owner: SinLess Games LLC (Timothy “Andy” Andrew Pierce / sinless777)
Status: DRAFT (Active Development)
Last Updated: 2025-12-27
Review Cadence: Update on material infra or platform changes (minimum quarterly)
```

This document describes the target-state architecture for the **SinLess Games** infrastructure platform:

* **Proxmox VE** as the virtualization/hypervisor layer (clustered)
* **Ceph (Proxmox-integrated)** for shared storage where appropriate
* **Kubernetes (Rancher K3s family via RKE2 tooling)** for cluster workloads
* **GitOps (FluxCD)** for cluster state and application delivery
* **Zero Trust** posture end-to-end (Vault, WireGuard, OIDC SSO, mTLS, Cloudflare)
* **Full observability** (Grafana stack + Grafana OnCall)
* **Backups/DR** via **Proxmox Backup Server (PBS)** and **Velero**

## Goals

* Reproducible, automated infrastructure managed as code.
* Strong isolation of management, storage, control-plane, and DMZ traffic.
* Progressive delivery with canary + promotion workflows.
* Secrets and PKI managed centrally with Vault.
* Compliance-ready controls with auditable change management.

## Non-goals

* “Live moving pods between clusters.” Promotions happen through Git (env overlays), not runtime teleportation.
* Exposing management planes directly to the public Internet.

---

# 1. Proxmox Cluster Overview

**Cluster Name:** SinLess-Games
**Nodes:** pve-01, pve-02, pve-03, pve-04, pve-05
**Backend Storage:** Ceph (Proxmox-integrated), plus node-local storage where required

## Hardware capability notes

* **10Gb-capable nodes:** pve-01, pve-04, pve-05
* **Service-heavy nodes:** pve-02 and pve-03 host critical management services (MinIO, Vault, GitLab)
* **Ceph OSD layout:** pve-02 and pve-03 include OSDs grouped into explicit storage classes (details below)

## Network VLANs

|            Plane | VLAN | Purpose                                                    | Access Model                                        |
| ---------------: | :--: | ---------------------------------------------------------- | --------------------------------------------------- |
|       Management |  10  | Proxmox UI/API/SSH, OOB tooling                            | WireGuard overlay and/or Cloudflare Zero Trust only |
|   Infra/Services |  20  | Shared platform services (Vault, MinIO, GitLab, DNS)       | Restricted; no public inbound                       |
| Kubernetes/Nodes |  30  | K8s node traffic, control-plane, internal LBs              | Restricted; no public inbound                       |
|          Storage |  40  | Ceph replication / storage backend traffic                 | Restricted, 10Gb where possible                     |
|              DMZ |  50  | Ingress / externally exposed services (through Cloudflare) | No direct inbound; Cloudflare Tunnel preferred      |

> **Addressing:** Subnets and IPs are defined in `environments/*/networking/` (source-of-truth). This document describes planes and intent.

---

# 2. Proxmox Access and Load Balancing

## Proxmox UI VIP + Round Robin

**Requirement:** A stable entrypoint for the Proxmox dashboard with **Keepalived + HAProxy**, using **round-robin** distribution.

### Design

* **Keepalived** provides a **VRRP virtual IP (VIP)** on the **Management VLAN (10)**.
* **HAProxy** listens on the VIP and load-balances to the Proxmox web UIs on each node.
* **Round Robin** is the default algorithm; health checks remove down nodes.

### Placement

* Run Keepalived + HAProxy on **two dedicated service endpoints** for HA (recommended):

  * Option A: small VMs on the Proxmox cluster
  * Option B: containers/VMs hosted primarily on **pve-02** and **pve-03** (preferred given service focus)

### Notes

* The Proxmox UI is stateful per session, but generally tolerant of LB distribution if:

  * stickiness is enabled (optional), and
  * health checks are strict.
* Administrative access should still be gated by:

  * WireGuard overlay, and/or
  * Cloudflare Zero Trust (preferred external access method).

---

# 3. Storage Architecture

## Ceph (Proxmox-integrated)

Ceph provides resilient shared storage for VM disks and critical services.

### Network separation

* **Client / public network:** VLAN 30 (Kubernetes/Nodes) and/or VLAN 20 (Infra/Services) depending on consumer
* **Cluster replication network:** VLAN 40 (Storage)

### OSD groups / storage classes

* pve-02 and pve-03 contain OSDs assigned into explicit groups (example model):

  * `ceph-ssd-fast` (low latency workloads)
  * `ceph-hdd-bulk` (capacity workloads)

This grouping maps to:

* Proxmox storage definitions (different pools), and
* Kubernetes storage classes (via CSI if/when Ceph is exposed to K8s)

### Kubernetes persistent storage

Initial approach options (documented as decisions):

1. **Expose Proxmox Ceph to Kubernetes via CSI (RBD/CephFS)**

   * Pros: single Ceph cluster to operate
   * Cons: careful key/secret management required

2. **Kubernetes-local storage for dev + selective stateful services**

   * Pros: lowest complexity early
   * Cons: less portable; not HA

Target state favors **option 1** for staging/prod once operational maturity is validated.

---

# 4. Core Platform Services

These services run on the Proxmox layer (VMs or containers), primarily on **pve-02** and **pve-03**.

## Authentik (SSO/OIDC)

**Role:** Central identity provider for:

* Proxmox (OIDC realm)
* Kubernetes (OIDC auth for kubectl + dashboard-facing apps)
* Grafana, Kiali, GitLab, Technitium UI, etc.

**Principles:**

* MFA enforced for privileged access
* Least privilege group mappings
* Audit trails enabled

## Vault

**Role:**

* Secrets management
* PKI / certificate lifecycle (where applicable)
* Short-lived credentials for automation and services

**Integration patterns:**

* Nodes and CI authenticate using short-lived identities (OIDC/JWT-based where possible)
* Kubernetes uses External Secrets Operator (or Vault CSI) to consume secrets without hardcoding

## MinIO (Local S3)

**Role:** Local, on-prem S3-compatible storage.

Primary uses:

* **Velero backup target**
* Artifact storage (selected pipelines)
* Optional: Loki/Mimir object storage backends (by environment)

Deployment:

* HA across pve-02 and pve-03 (plus optional 3rd instance if desired)
* Backed by Ceph or local disks depending on performance goals

## GitLab

**Role:**

* Internal Git hosting and CI runners (optional, complementary to GitHub)
* Artifact registry / container registry (optional)

GitHub remains the canonical repo for infrastructure, but GitLab may be used for internal workflows.

## Technitium DNS

**Role:** Local DNS for:

* split-horizon zones
* internal service discovery
* local domain mapping (lab/dev)

Interoperability:

* Cloudflare remains authoritative DNS for public domains
* Technitium handles internal zones and optionally forwards/conditional forwards

## Multi-domain support

The platform supports multiple domain names by design:

* Public DNS managed via Cloudflare
* Internal zones managed via Technitium
* Kubernetes ingress rules and cert issuance are domain-agnostic (values-driven)

---

# 5. Kubernetes Architecture

## Kubernetes distro

* **Rancher K3s family via RKE2 tooling** (lightweight footprint, operationally simple)
* HA-ready control-plane topology

## Clusters

Three clusters are maintained with GitOps separation:

* **dev**
* **staging**
* **prod**

Cluster definitions (VM counts, sizing, networks) are environment-driven in repo configuration.

## Networking

* Node traffic and service LBs live on VLAN 30
* Ingress exposure follows a **Cloudflare-first** model (Tunnel + Access)
* East-west security uses:

  * Kubernetes NetworkPolicies (Cilium/Calico decision tracked in DECISIONS)
  * Istio mTLS for service-to-service where enabled

## GitOps

* **FluxCD** bootstraps each cluster from its own path:

  * `kubernetes/clusters/dev`
  * `kubernetes/clusters/staging`
  * `kubernetes/clusters/prod`

Promotion model:

* dev → staging → prod is a Git change (PR-based), not runtime drift

## Progressive delivery

* **Istio + Flagger** for in-cluster canaries
* Canary policies are declared per app (metric checks, traffic shifting, rollback)

---

# 6. Certificates, DNS, and External Access

## Certificates

* **cert-manager** issues certificates using **Cloudflare DNS-01**
* Certificates must be centrally recoverable:

  * cert-manager stores active certs as Kubernetes Secrets
  * a controlled sync mechanism stores cert material in Vault (for recovery / non-K8s consumers)

> Target state: prefer Vault-backed PKI for internal certs and ACME for public certs; both patterns supported.

## External Access

Primary external access path:

* **Cloudflare Tunnels**
* **Cloudflare Access** policies (OIDC with Authentik or upstream IdP)

No public inbound ports to management planes.

---

# 7. Observability and Incident Response

## Telemetry stack

* Metrics: Prometheus → (optional) Mimir
* Logs: Loki
* Traces: Tempo
* Profiles: Pyroscope
* Collection/agent: Alloy + (optional) Beyla
* Mesh observability: Kiali

## Alerting and on-call

* Grafana Alerting
* **Grafana OnCall** for escalation policies, routing, and schedules

## Proxmox metrics

* Proxmox metrics forwarded into InfluxDB (or Prometheus exporters where beneficial)
* Grafana dashboards for:

  * node health
  * VM health
  * Ceph health
  * network utilization per VLAN/plane

---

# 8. Backups and Disaster Recovery

## Proxmox Backup Server (PBS)

* VM and container backups
* Policy-managed retention and encryption
* Regular restore drills documented and scheduled

## Kubernetes backups with Velero

* Cluster state and namespace resources
* PV backups/snapshots where supported
* **Backup target:** MinIO (local S3)

Offsite strategy (target state):

* replicate MinIO buckets and/or PBS datastores to an offsite location (cloud or secondary site)

---

# 9. Security Model

## Identity and access

* Authentik provides SSO via OIDC
* RBAC is defined as code:

  * Proxmox roles and groups
  * Kubernetes roles and bindings
  * App-level access policies

## Zero Trust principles

* Management traffic restricted to WireGuard overlay and/or Cloudflare Access
* No public inbound ports to management networks
* mTLS in-cluster (Istio) where enabled
* Vault as central secrets authority

## Policy-as-code

* Kubernetes admission controls (Kyverno or Gatekeeper)
* IaC scanning in CI (Terraform, container, YAML)
* Signed artifacts / provenance (planned)

---

# 10. Environment Differences

The architecture is consistent across environments, with differences in:

* scale (VM counts, resources)
* data retention (observability and backups)
* change controls (PR approvals and deployment gates)

The canonical place for environment variance is:

* `environments/dev/`
* `environments/staging/`
* `environments/prod/`

---

# 11. Operational Conventions

## Naming

* Proxmox nodes: `pve-01` … `pve-05`
* Kubernetes clusters: `dev`, `staging`, `prod`
* VLAN naming: `mgmt`, `infra`, `k8s`, `storage`, `dmz`

## Source of truth

* Git is the change-control system.
* Production changes require PRs, approvals, and passing automation.

---

# 12. Open Decisions and Next Steps

Track these in `docs/architecture/DECISIONS.md`:

* CNI choice (Cilium vs Calico) and whether to enable WireGuard encryption for pod traffic
* Exposing Ceph to Kubernetes (CSI) timeline and secret handling
* Vault topology (in-cluster vs external vs hybrid)
* GitLab placement (VM vs in-cluster) and storage strategy
* Hybrid bursting approach (Cluster API / Crossplane / provider-specific scaling)

Recommended next step:

* Finalize `DECISIONS.md` with concrete choices and acceptance criteria.
