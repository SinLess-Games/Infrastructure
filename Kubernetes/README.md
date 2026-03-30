# Kubernetes Layout

This directory is organized for a mixed model:

- `clusters/flux/`: the shared FluxCD sync entrypoint for GitOps-managed clusters.
- `clusters/dev/`: local or manually applied development manifests.
- `apps/base/`: reusable application manifests.
- `apps/<env>/`: environment-specific application composition.
- `infrastructure/`: shared cluster services, controllers, and supporting config.

Current operating model:

- `dev` is not managed by FluxCD.
- FluxCD manages both `staging` and `prod` from the shared `clusters/flux/` entrypoint.
- Shared manifests should be included once from `clusters/flux/` to avoid duplicate objects across environments.

Recommended growth pattern:

- Put reusable app manifests in `apps/base/<app>/`.
- Put staging-only manifests in `apps/staging/`.
- Put production-only manifests in `apps/prod/`.
- Include shared resources once from `clusters/flux/`.
- Add Flux bootstrap output under `clusters/flux/flux-system/`.

Expected Flux bootstrap output:

- `clusters/flux/flux-system/gotk-components.yaml`
- `clusters/flux/flux-system/gotk-sync.yaml`
