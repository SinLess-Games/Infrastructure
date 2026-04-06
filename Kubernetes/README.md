# Kubernetes Layout

This directory now supports a production Argo CD operating model while preserving the existing cluster entrypoints.

Top-level conventions:

- `clusters/<env>/`: environment bootstrap entrypoints and cluster-level docs.
- `apps/prod/<namespace>/`: production applications grouped by namespace ownership.
- `validation/prod/`: production health checks, smoke tests, and debugging helpers.
- `infrastructure/`: shared notes and legacy infrastructure guidance.

Production conventions:

- Every namespace has its own folder and `namespace.yaml`.
- Helm values, mesh policies, examples, and Kustomize overlays live under the namespace they belong to.
- Argo CD applications point at these namespace-scoped folders and values files.
- Phase ordering is expressed with Argo CD sync waves plus bootstrap documentation.

Legacy Flux content remains in place for compatibility, but the production source of truth in this change set is the Argo CD layout under `clusters/prod` and `apps/prod`.
