# Architectural Decisions

**Document:** `Docs/Architecture/DECISIONS.md`  
**Owner:** SinLess Games LLC (Timothy “Andy” Andrew Pierce / sinless777)  
**Status:** ACCEPTED  
**Last Updated:** 2026-04-25  
**Scope:** Architecture Decision Records for the SinLess Games infrastructure platform.

This document is the index and governance record for infrastructure architecture decisions.

Each linked file is an Architecture Decision Record (ADR). ADRs document finalized architectural decisions, accepted implementation direction, operational requirements, validation requirements, and rollback requirements.

---

## Purpose

This decision index exists to make infrastructure decisions:

- stable
- reviewable
- auditable
- searchable
- linked to implementation
- linked to validation
- linked to rollback procedures

Architecture changes must be captured in ADRs when they affect platform direction, control boundaries, tool selection, operating model, data placement, security posture, deployment flow, or disaster recovery behavior.

---

## ADR Governance

ADR files live under:

```text
Docs/Architecture/ADRs/
````

ADR filenames use this format:

```text
ADR-0000.md
```

ADR IDs are immutable.

When a decision changes, create a new ADR that supersedes the old ADR.

Do not rewrite historical decision intent. Existing ADRs may be updated to correct implementation details, ownership, validation, diagrams, and current status, but major direction changes require a superseding ADR.

ADR references should be used in:

* pull requests
* issues
* runbooks
* infrastructure changes
* Kubernetes manifests
* policy exceptions
* incident response records
* compliance evidence
* documentation updates

---

## Decision Status Definitions

| Status       | Meaning                                                                                     |
| ------------ | ------------------------------------------------------------------------------------------- |
| `DRAFT`      | Proposed, under discussion, not yet implemented.                                            |
| `ACCEPTED`   | Approved direction; implementation planned or in progress.                                  |
| `DEPRECATED` | No longer recommended; maintained only for legacy.                                          |
| `SUPERSEDED` | Replaced by a newer ADR.                                                                    |
| `DENIED`     | Explicitly rejected as the platform direction. Kept to document why the option is not used. |

---

## Review Rules

ADRs must be reviewed when:

* the selected tool changes
* the deployment model changes
* the security boundary changes
* the data placement model changes
* the production environment changes
* the rollback procedure changes
* the validation procedure changes
* a related incident exposes a design gap
* a compliance requirement changes
* implementation no longer matches the decision

Accepted ADRs should be reviewed at least quarterly or during major platform changes.

---

## Decision Index

| ADR                            | Title                                                                         | Status   | Owner             | Last Reviewed |
| ------------------------------ | ----------------------------------------------------------------------------- | -------- | ----------------- | ------------- |
| [ADR-0001](./ADRs/ADR-0001.md) | Monorepo as the source of truth                                               | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0002](./ADRs/ADR-0002.md) | Proxmox cluster topology                                                      | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0003](./ADRs/ADR-0003.md) | Network segmentation with VLAN planes                                         | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0004](./ADRs/ADR-0004.md) | Proxmox dashboard HA with Keepalived VIP and HAProxy                          | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0005](./ADRs/ADR-0005.md) | Ceph storage model                                                            | DENIED   | SinLess Games LLC | 2025-12-27    |
| [ADR-0006](./ADRs/ADR-0006.md) | Kubernetes distribution choice: RKE2                                          | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0007](./ADRs/ADR-0007.md) | GitOps controller: Argo CD                                                    | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0008](./ADRs/ADR-0008.md) | Progressive delivery with Istio and Argo Rollouts                             | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0009](./ADRs/ADR-0009.md) | Identity and SSO with Authentik                                               | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0010](./ADRs/ADR-0010.md) | Certificate management with cert-manager, Cloudflare DNS-01, and Vault        | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0011](./ADRs/ADR-0011.md) | External access with Cloudflare Tunnel and Cloudflare Access                  | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0012](./ADRs/ADR-0012.md) | Secrets management and PKI with HashiCorp Vault                               | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0013](./ADRs/ADR-0013.md) | Backups and disaster recovery with PBS, Velero, and Garage                    | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0014](./ADRs/ADR-0014.md) | Observability and IRM with Grafana Stack, OpenTelemetry, Kiali, and DFIR-IRIS | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0015](./ADRs/ADR-0015.md) | Hybrid burst strategy for cloud expansion                                     | DRAFT    | SinLess Games LLC | 2025-12-27    |
| [ADR-0016](./ADRs/ADR-0016.md) | Policy-as-code enforcement with Kyverno                                       | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0017](./ADRs/ADR-0017.md) | GitHub source control, CI/CD, and registry operating model                    | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0018](./ADRs/ADR-0018.md) | Garage object storage placement and operating model                           | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0019](./ADRs/ADR-0019.md) | Management overlay with WireGuard                                             | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0020](./ADRs/ADR-0020.md) | Security and compliance operating model                                       | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0021](./ADRs/ADR-0021.md) | Kubernetes persistent storage with Longhorn                                   | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0022](./ADRs/ADR-0022.md) | Database and stateful platform service placement                              | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0023](./ADRs/ADR-0023.md) | Istio service mesh operating model                                            | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0024](./ADRs/ADR-0024.md) | Ingress, gateway, DNS, and TLS routing model                                  | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0025](./ADRs/ADR-0025.md) | GitHub Actions Runner Controller and agentic workflow operating model         | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0026](./ADRs/ADR-0026.md) | Container image supply chain, signing, SBOM, and provenance                   | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0027](./ADRs/ADR-0027.md) | RKE2 cluster node topology and scheduling model                               | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0028](./ADRs/ADR-0028.md) | NVIDIA GPU worker and runtime model                                           | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0029](./ADRs/ADR-0029.md) | Internal DNS and name resolution model                                        | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0030](./ADRs/ADR-0030.md) | Infrastructure provisioning with Terraform and Ansible                        | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0031](./ADRs/ADR-0031.md) | PXE and bootstrap automation with netboot.xyz                                 | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0032](./ADRs/ADR-0032.md) | Namespace, application layout, and GitOps repository structure                | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0033](./ADRs/ADR-0033.md) | PostgreSQL operating model                                                    | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0034](./ADRs/ADR-0034.md) | Incident response workflow with DFIR-IRIS                                     | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0035](./ADRs/ADR-0035.md) | Documentation platform with MkDocs Material                                   | ACCEPTED | SinLess Games LLC | 2026-04-25    |
| [ADR-0036](./ADRs/ADR-0036.md) | Kubernetes cluster flow progression and DevSecOps operating model             | ACCEPTED | SinLess Games LLC | 2026-04-25    |

---

## Decision Coverage Map

### Repository, Source Control, and Documentation

| Area                                         | ADR                            |
| -------------------------------------------- | ------------------------------ |
| Monorepo source of truth                     | [ADR-0001](./ADRs/ADR-0001.md) |
| GitHub, CI/CD, and registry model            | [ADR-0017](./ADRs/ADR-0017.md) |
| GitHub Actions runners and agentic workflows | [ADR-0025](./ADRs/ADR-0025.md) |
| Container image supply chain                 | [ADR-0026](./ADRs/ADR-0026.md) |
| Documentation platform                       | [ADR-0035](./ADRs/ADR-0035.md) |
| DevSecOps progression                        | [ADR-0036](./ADRs/ADR-0036.md) |

### Proxmox, Provisioning, and Bootstrap

| Area                         | ADR                            |
| ---------------------------- | ------------------------------ |
| Proxmox topology             | [ADR-0002](./ADRs/ADR-0002.md) |
| Proxmox dashboard HA         | [ADR-0004](./ADRs/ADR-0004.md) |
| Infrastructure provisioning  | [ADR-0030](./ADRs/ADR-0030.md) |
| PXE and bootstrap automation | [ADR-0031](./ADRs/ADR-0031.md) |
| GPU passthrough and runtime  | [ADR-0028](./ADRs/ADR-0028.md) |

### Network, DNS, Ingress, and Access

| Area                                   | ADR                            |
| -------------------------------------- | ------------------------------ |
| VLAN segmentation                      | [ADR-0003](./ADRs/ADR-0003.md) |
| Cloudflare Tunnel and Access           | [ADR-0011](./ADRs/ADR-0011.md) |
| Management overlay with WireGuard      | [ADR-0019](./ADRs/ADR-0019.md) |
| Ingress, gateway, DNS, and TLS routing | [ADR-0024](./ADRs/ADR-0024.md) |
| Internal DNS and name resolution       | [ADR-0029](./ADRs/ADR-0029.md) |

### Kubernetes Platform

| Area                                  | ADR                            |
| ------------------------------------- | ------------------------------ |
| Kubernetes distribution               | [ADR-0006](./ADRs/ADR-0006.md) |
| GitOps controller                     | [ADR-0007](./ADRs/ADR-0007.md) |
| Progressive delivery                  | [ADR-0008](./ADRs/ADR-0008.md) |
| Policy-as-code                        | [ADR-0016](./ADRs/ADR-0016.md) |
| Service mesh                          | [ADR-0023](./ADRs/ADR-0023.md) |
| RKE2 node topology and scheduling     | [ADR-0027](./ADRs/ADR-0027.md) |
| Namespace and application layout      | [ADR-0032](./ADRs/ADR-0032.md) |
| Environment progression and DevSecOps | [ADR-0036](./ADRs/ADR-0036.md) |

### Storage, Data, and Recovery

| Area                                             | ADR                            |
| ------------------------------------------------ | ------------------------------ |
| Ceph storage decision                            | [ADR-0005](./ADRs/ADR-0005.md) |
| Backups and disaster recovery                    | [ADR-0013](./ADRs/ADR-0013.md) |
| Garage object storage                            | [ADR-0018](./ADRs/ADR-0018.md) |
| Kubernetes persistent storage with Longhorn      | [ADR-0021](./ADRs/ADR-0021.md) |
| Database and stateful platform service placement | [ADR-0022](./ADRs/ADR-0022.md) |
| PostgreSQL operating model                       | [ADR-0033](./ADRs/ADR-0033.md) |

### Identity, Secrets, Security, and Compliance

| Area                                    | ADR                            |
| --------------------------------------- | ------------------------------ |
| Identity and SSO                        | [ADR-0009](./ADRs/ADR-0009.md) |
| Certificate management                  | [ADR-0010](./ADRs/ADR-0010.md) |
| Vault secrets and PKI                   | [ADR-0012](./ADRs/ADR-0012.md) |
| Security and compliance operating model | [ADR-0020](./ADRs/ADR-0020.md) |
| Incident response workflow              | [ADR-0034](./ADRs/ADR-0034.md) |

### Observability and Operations

| Area                       | ADR                            |
| -------------------------- | ------------------------------ |
| Observability and IRM      | [ADR-0014](./ADRs/ADR-0014.md) |
| Incident response workflow | [ADR-0034](./ADRs/ADR-0034.md) |
| Documentation platform     | [ADR-0035](./ADRs/ADR-0035.md) |

### Cloud Expansion

| Area                  | ADR                            |
| --------------------- | ------------------------------ |
| Hybrid burst strategy | [ADR-0015](./ADRs/ADR-0015.md) |

---

## Current Accepted Platform Baseline

The accepted platform baseline is:

| Layer                         | Accepted Decision                                                    |
| ----------------------------- | -------------------------------------------------------------------- |
| Source of truth               | GitHub monorepo                                                      |
| Hypervisor                    | Proxmox                                                              |
| Infrastructure provisioning   | Terraform                                                            |
| Host configuration            | Ansible                                                              |
| Network segmentation          | VLAN planes                                                          |
| Kubernetes distribution       | RKE2                                                                 |
| Kubernetes environments       | `dev`, `staging`, `prod`                                             |
| GitOps                        | Argo CD                                                              |
| Progressive delivery          | Argo Rollouts with Istio                                             |
| Service mesh                  | Istio                                                                |
| Policy-as-code                | Kyverno                                                              |
| Identity provider             | Authentik                                                            |
| Secrets and PKI               | HashiCorp Vault                                                      |
| Certificate management        | cert-manager with Cloudflare DNS-01                                  |
| Public DNS                    | Cloudflare                                                           |
| Public ingress path           | Cloudflare Tunnel and Istio Gateway                                  |
| Management overlay            | WireGuard                                                            |
| Kubernetes persistent storage | Longhorn                                                             |
| Object storage                | Garage                                                               |
| VM backup                     | Proxmox Backup Server                                                |
| Kubernetes backup             | Velero                                                               |
| Database runtime placement    | Vault and PostgreSQL on VMs                                          |
| Relational database           | PostgreSQL                                                           |
| Observability                 | Grafana stack, OpenTelemetry, Kiali                                  |
| Incident response management  | DFIR-IRIS                                                            |
| Security stack                | CrowdSec, Falco, Trivy, Wazuh, Dependabot, Renovate, Mend.io, CodeQL |
| CI/CD                         | GitHub Actions                                                       |
| Self-hosted runners           | Actions Runner Controller                                            |
| Container registry            | GHCR                                                                 |
| Documentation                 | MkDocs Material                                                      |
| PXE bootstrap                 | netboot.xyz                                                          |

---

## Environment Model

The accepted Kubernetes environments are:

| Environment | Purpose                                          |
| ----------- | ------------------------------------------------ |
| `dev`       | Fast integration and early validation            |
| `staging`   | Production-like validation and rollout rehearsal |
| `prod`      | Live production workloads                        |

The accepted promotion flow is:

```text
feature branch
  → pull request
  → CI validation
  → dev
  → staging
  → production approval
  → prod
```

Production changes require review, security validation, staging validation, protected environment approval, GitOps reconciliation, and rollback evidence.

---

## ADR Creation Requirements

Create a new ADR when a change affects:

* platform architecture
* tool selection
* runtime placement
* data placement
* storage backend
* ingress model
* identity model
* secret model
* CI/CD model
* GitOps model
* security boundary
* compliance scope
* backup and recovery behavior
* production deployment flow
* management access
* node topology
* network segmentation
* operational ownership
* validation requirements
* rollback requirements

Do not create a new ADR for routine implementation details that do not change architecture direction.

---

## ADR Maintenance Requirements

Every ADR must include:

* ADR number
* title
* owner
* status
* date accepted
* last updated
* supersedes
* superseded by
* related documents
* context
* decision
* alternatives considered
* rationale
* implementation requirements
* validation requirements
* rollback plan
* operational requirements

ADRs must contain finalized decision content and required implementation or validation content.

ADRs must not contain suggestion sections, optional follow-up ideas, or speculative recommendation sections.

---

## Reserved Future ADRs

No future ADR is required for the current accepted baseline.

New ADRs begin at:

```text
ADR-0037
```

Future ADRs are created only when a new architectural decision is finalized or an existing decision requires supersession.
