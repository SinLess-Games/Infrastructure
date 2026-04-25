# Architecture

This section documents the infrastructure architecture, platform decisions, and operational design for the SinLess Games infrastructure environment.

The architecture documentation is intended to be the source of truth for how the platform is designed, why major decisions were made, and how the environment should be validated, operated, and extended.

## Architecture Documents

| Document | Purpose |
|---|---|
| [ACME Architecture](./ACME-Architecture.md) | Primary architecture overview for infrastructure, platform, GitOps, Kubernetes, networking, storage, observability, and security. |
| [Architecture Decisions](./DECISIONS.md) | Index of accepted, draft, deprecated, superseded, and denied architecture decisions. |
| [Architecture Decision Records](./ADRs/) | Individual ADR files documenting finalized architecture decisions and implementation requirements. |

## Architecture Scope

The infrastructure architecture covers the following platform areas:

- Proxmox virtualization
- RKE2 Kubernetes clusters
- Development, staging, and production environments
- GitOps deployment patterns
- Argo CD application management
- Cilium networking
- Istio service mesh
- Longhorn storage
- External Secrets and Vault integration
- Cloudflare DNS, tunnels, and certificate automation
- Observability with Grafana, Prometheus, Loki, Tempo, Mimir, Pyroscope, and Alloy
- Security tooling including Kyverno, Falco, Wazuh, and network policy enforcement
- Backup and recovery workflows
- Self-hosted platform services
- CI/CD and automation workflows
- PXE and netboot provisioning

## Environment Model

The platform is organized into three Kubernetes environments:

| Environment | Purpose |
|---|---|
| `dev` | Development workloads, testing, early integration, and non-production validation. |
| `staging` | Pre-production validation environment that mirrors production behavior where practical. |
| `prod` | Production workloads and externally exposed services. |

Each environment must have a clear separation of workloads, secrets, GitOps applications, ingress policies, monitoring, and operational controls.

## Platform Principles

The architecture follows these principles:

1. **GitOps first**  
   Desired state is declared in Git and reconciled into the cluster by GitOps tooling.

2. **Infrastructure as code**  
   Provisioning, configuration, and deployment should be reproducible through Terraform, Ansible, Helm, Kustomize, and Kubernetes manifests.

3. **Secure by default**  
   Workloads should use least privilege, non-root execution, scoped RBAC, network policies, secret isolation, and policy enforcement.

4. **Zero-trust internal networking**  
   Internal service communication should be explicitly controlled and authenticated where supported by the platform.

5. **Observable by default**  
   Platform services must expose logs, metrics, traces, dashboards, and alerts needed for operations and incident response.

6. **Recoverable by design**  
   Backups, restore procedures, storage policies, and disaster recovery requirements must be documented and validated.

7. **Environment parity where practical**  
   Development, staging, and production should share the same architecture patterns while allowing resource sizing differences.

8. **Operational validation required**  
   Platform changes should include validation commands, smoke tests, and rollback considerations when applicable.

## Decision States

Architecture decisions use the following states:

| State | Meaning |
|---|---|
| `DRAFT` | Proposed, under discussion, not yet implemented. |
| `ACCEPTED` | Approved direction; implementation planned or in progress. |
| `DEPRECATED` | No longer recommended; maintained only for legacy. |
| `SUPERSEDED` | Replaced by a newer ADR. |
| `DENIED` | Reviewed and explicitly rejected. |

## Recommended Reading Order

For a complete understanding of the platform architecture, read the documents in this order:

1. [ACME Architecture](./ACME-Architecture.md)
2. [Architecture Decisions](./DECISIONS.md)
3. [Architecture Decision Records](./ADRs/)

## Documentation Standards

Architecture documentation should be:

- Clear enough to support implementation.
- Specific enough to validate.
- Updated when architecture decisions change.
- Linked to related ADRs where applicable.
- Free of speculative recommendations in finalized ADRs.
- Focused on decisions, requirements, implementation details, and validation steps.

## Ownership

Architecture documentation is maintained as part of the infrastructure repository and should be updated alongside platform changes.

Any change that modifies platform direction, security posture, networking model, storage design, GitOps structure, cluster lifecycle, or operational responsibility should be reflected in the appropriate architecture document or ADR.