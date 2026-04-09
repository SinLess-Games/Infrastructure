# GitOps Layer

`apps/prod/gitops/` is the Argo CD control surface for the production cluster.

## How To Use It

- `applications/`
  Put Argo CD `Application` manifests here for namespace-local bundles and platform components.
- `config/`
  Put GitOps support resources here, such as ExternalSecrets and config that the GitOps namespace itself needs.

## Rule

If Argo CD should manage something in production, the routing object that tells Argo CD where to look belongs here.
