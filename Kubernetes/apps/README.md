# Apps Layout

Use `apps/` for namespace-scoped Kubernetes content that Argo CD reconciles.

## Production

- `prod/gitops/`
  Contains Argo CD `Application`, `ApplicationSet`, and GitOps support config.
  This is the control layer Argo CD uses to discover and manage the rest of the cluster apps.
- `prod/<namespace>/`
  Contains the manifests for one namespace.
  Keep namespace creation, policies, mesh config, app manifests, ExternalSecrets, and Helm values under the namespace that owns them.

## Working Rule

When you add or change a production app:

1. Put the workload manifests in `apps/prod/<namespace>/...`
2. Add or update the matching Argo CD `Application` in `apps/prod/gitops/applications/`
3. Let Argo CD reconcile it

Do not create parallel app trees outside the namespace structure.
