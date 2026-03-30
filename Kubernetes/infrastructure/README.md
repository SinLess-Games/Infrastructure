# Infrastructure Layer

Use this directory for cluster-level services managed by FluxCD, for example:

- ingress controllers
- cert-manager
- external-dns
- CSI/storage controllers
- monitoring/logging stacks
- policy engines

Suggested structure:

- `controllers/`: infrastructure applications and Helm releases.
- `configs/`: shared namespaces, secrets templates, policies, and cluster config.
