# Kubernetes Layout

This directory is the Kubernetes source of truth for the production cluster. Argo CD manages cluster GitOps from the manifests in this tree.

## Folder Guide

- `clusters/`
  Use this for cluster bootstrap entrypoints only.
  `clusters/prod/` contains the minimal Argo CD bootstrap objects that create the `platform` project and the root app-of-apps.
- `apps/`
  Use this for namespace-owned application and policy content.
  `apps/prod/<namespace>/` is the main working area for production changes.
- `validation/`
  Use this for health checks, smoke tests, debug helpers, and validation matrices that operators run against the live cluster.

## How GitOps Works

1. Bootstrap Argo CD with the production playbook.
2. Apply `Kubernetes/clusters/prod`.
3. Argo CD creates `prod-platform-root`.
4. `prod-platform-root` reconciles `Kubernetes/apps/prod/gitops/applications`.
5. Those `Application` objects manage every platform app in the cluster.

Production apps should not be deployed from ad hoc directories, one-off `helm install` commands, or legacy overlay trees. If an app belongs in the cluster, it should be represented under `apps/prod/<namespace>/` and reconciled by Argo CD.

## Namespace Convention

Each production namespace gets its own folder under `apps/prod/`:

- `namespace/`: the namespace manifest and required labels or annotations
- `policies/`: quotas, limit ranges, network policies, peer auth, authz, and related safeguards
- `mesh/`: Istio `VirtualService`, `DestinationRule`, `Gateway` consumers, and namespace mesh config
- app-specific folders:
  Helm values, raw manifests, ExternalSecrets, services, stateful workloads, and supporting config for that namespace

Examples:

- `apps/prod/kube-system/` for core cluster add-ons
- `apps/prod/monitoring/` for observability services
- `apps/prod/security/` for ESO, Kyverno, Falco, Velero, and security controls
- `apps/prod/sinless-games/` for SinLess Games platform and shared edge workloads such as Garage

## What Was Removed

The following legacy or placeholder-only paths were removed because they were not part of the live Argo CD production flow:

- old placeholder `apps/base/`
- unused `apps/dev/` and `apps/staging/`
- unused `clusters/dev/`
- legacy `infrastructure/`
- unused top-level `helm-values/` staging area

That cleanup leaves one clear path:

- bootstrap from `clusters/prod/`
- operate apps from `apps/prod/`
- validate with `validation/prod/`
