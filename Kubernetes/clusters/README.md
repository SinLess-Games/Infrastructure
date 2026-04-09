# Cluster Bootstrap

Use `clusters/` only for environment bootstrap entrypoints.

## Production

- `prod/bootstrap/project-platform.yaml`
  Creates the Argo CD `AppProject` that authorizes platform sources and destinations.
- `prod/bootstrap/app-of-apps.yaml`
  Creates the root Argo CD `Application` that points at `Kubernetes/apps/prod/gitops/applications`.
- `prod/kustomization.yaml`
  Minimal bootstrap wrapper for those resources.

## Rule

Keep cluster bootstrap small. Once Argo CD is online, app ownership belongs under `Kubernetes/apps/prod/`, not under `clusters/`.
