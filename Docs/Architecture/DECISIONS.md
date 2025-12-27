```text
Document: DECISIONS.md
Owner: SinLess Games LLC (Timothy “Andy” Andrew Pierce / sinless777)
Status: DRAFT (Active Development)
Last Updated: 2025-12-27
Scope: Architectural decisions for the SinLess Games infrastructure platform.
```

# Architectural Decisions (ADRs)

This document records **why** key architectural choices were made, what alternatives were considered, and the operational consequences. These decisions are meant to be stable, reviewable, and auditable.

## How to use this document

* Treat each section as an **ADR** (Architectural Decision Record).
* If a decision changes, **add a new ADR** that supersedes the old one (do not rewrite history).
* Reference ADR IDs in PRs, issues, and change logs.

## Decision status definitions

* **DRAFT** — proposed, under discussion, not yet implemented.
* **ACCEPTED** — approved direction; implementation planned or in progress.
* **IMPLEMENTED** — in place in the environment(s).
* **DEPRECATED** — no longer recommended; maintained only for legacy.
* **SUPERSEDED** — replaced by a newer ADR.

---

# Index

| ADR      | Title                                                                  | Status   | Owner             | Last Reviewed |
| -------- | ---------------------------------------------------------------------- | -------- | ----------------- | ------------- |
| [ADR-0001](./ADRs/ADR-0001.md) | Monorepo as the source of truth                                        | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0002](./ADRs/ADR-0002.md) | Proxmox cluster topology (pve-01…pve-05)                               | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0003](./ADRs/ADR-0003.md) | Network segmentation with VLAN planes                                  | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0004](./ADRs/ADR-0004.md) | Proxmox dashboard HA via Keepalived VIP + HAProxy RR                   | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0005](./ADRs/ADR-0005.md) | Ceph storage model (Proxmox-integrated) + OSD groups                   | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0006](./ADRs/ADR-0006.md) | Kubernetes distribution choice: Rancher K3s-family (Rancher ecosystem) | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0007](./ADRs/ADR-0007.md) | GitOps controller: FluxCD                                              | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0008](./ADRs/ADR-0008.md) | Progressive delivery: Istio + Flagger canaries                         | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0009](./ADRs/ADR-0009.md) | Identity and SSO: Authentik via OIDC                                   | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0010](./ADRs/ADR-0010.md) | Secrets and PKI: Vault + cert-manager (Cloudflare DNS-01)              | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0011](./ADRs/ADR-0011.md) | External access: Cloudflare Tunnel + Access (no inbound mgmt)          | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0012](./ADRs/ADR-0012.md) | Local DNS: Technitium + split-horizon with Cloudflare                  | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0013](./ADRs/ADR-0013.md) | Backups and DR: Proxmox Backup Server + Velero to MinIO S3             | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0014](./ADRs/ADR-0014.md) | Observability: Grafana stack + OnCall; InfluxDB for Proxmox            | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0015](./ADRs/ADR-0015.md) | Hybrid burst strategy (cloud expansion)                                | DRAFT    | SinLess Games LLC | 2025-12-27    |
| [ADR-0016](./ADRs/ADR-0016.md) | Policy-as-code enforcement approach                                    | DRAFT    | SinLess Games LLC | 2025-12-27    |
| [ADR-0017](./ADRs/ADR-0017.md) | GitLab placement and operating model                                   | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0018](./ADRs/ADR-0018.md) | MinIO placement and operating model                                    | ACCEPTED | SinLess Games LLC | 2025-12-27    |
| [ADR-0019](./ADRs/ADR-0019.md) | Management overlay: WireGuard                                          | ACCEPTED | SinLess Games LLC | 2025-12-27    |

---
