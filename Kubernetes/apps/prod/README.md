# Production Apps

`apps/prod/` is the production application catalog for the cluster.

## How To Use It

- `gitops/`
  Owns the Argo CD root `Application` objects and ApplicationSets.
  If Argo CD should manage a namespace folder, declare that relationship here.
- `<namespace>/namespace/`
  Namespace object with explicit labels and annotations.
- `<namespace>/policies/`
  Baseline policies such as quotas, limit ranges, network policies, peer auth, and authz.
- `<namespace>/mesh/`
  Istio routing and namespace mesh defaults.
- `<namespace>/<app>/`
  App-specific manifests or Helm values for a single service or component.

## Current Production Patterns

- `networking/cloudflared/`
  Owns Cloudflare tunnel connectors. In production this now runs domain-specific worker-node DaemonSets and pulls tunnel tokens from Vault-backed `ExternalSecret` objects.
- `networking/config/`
  Owns networking secrets and issuers that other networking apps depend on, such as Cloudflare API credentials for ExternalDNS and cert-manager.
- `monitoring/config/`
  Owns monitoring-side `ExternalSecret`, `VirtualService`, and `ServiceEntry` resources that expose internal operator endpoints through the shared Istio edge.
- `sinless-games/garage/`
  Owns the Garage S3 API, Garage Web UI, S3 credentials, storage class, and Istio routing for `s3.sinlessgames.com`.

## Production Rule

Every cluster app should be represented here and reconciled through Argo CD. If a component is live in production, there should be:

1. a namespace-owned folder here
2. an Argo CD `Application` or `ApplicationSet` that points to it
