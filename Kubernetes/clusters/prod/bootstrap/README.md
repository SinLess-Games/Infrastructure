# Production Bootstrap

This folder contains the minimal objects required to hand cluster app management over to Argo CD.

## Files

- `project-platform.yaml`
  Defines the Argo CD `AppProject` used by the production platform.
- `app-of-apps.yaml`
  Defines the root `Application` that points Argo CD at `Kubernetes/apps/prod/gitops/applications`.

## Rule

Keep this folder small. It should bootstrap GitOps, not duplicate the namespace app tree.
