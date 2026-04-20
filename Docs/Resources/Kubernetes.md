# Kubernetes Documentation and Resources

## What This Page Is For

This page is a curated Kubernetes reference map for platform engineering, cluster operations, security, observability, GitOps, and supporting infrastructure.

It is meant to make it easier to find the right documentation quickly instead of hunting across bookmarks, blog posts, or search results.

## Useful Sites

- [Cloud Native Computing Foundation (CNCF) Landscape](https://landscape.cncf.io/)
- [Artifact Hub](https://artifacthub.io/)
- [Kubernetes Blog](https://kubernetes.io/blog/)
- [Awesome Kubernetes](https://github.com/ramitsurana/awesome-kubernetes)

## Core Kubernetes Documentation

- [Kubernetes](https://kubernetes.io/docs/home/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [Kustomize](https://kustomize.io/)
- [Helm](https://helm.sh/docs/)
- [RKE2](https://docs.rke2.io/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)

## Platform Engineering and Control Planes

- [Crossplane](https://docs.crossplane.io/latest/)
- [Crossplane Guides](https://docs.crossplane.io/latest/guides/)
- [Crossplane Compositions and XRDs](https://docs.crossplane.io/latest/composition/composite-resource-definitions/)

## Networking, DNS, and Traffic Management

- [Cilium](https://docs.cilium.io/en/stable/)
- [Cilium Overview](https://docs.cilium.io/en/stable/overview/component-overview/)
- [CoreDNS](https://coredns.io/manual/toc/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Istio](https://istio.io/latest/docs/)
- [Kiali](https://kiali.io/docs/)
- [MetalLB](https://metallb.universe.tf/)
- [MetalLB Installation](https://metallb.universe.tf/installation/)
- [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/)
- [ExternalDNS Annotations](https://kubernetes-sigs.github.io/external-dns/latest/docs/annotations/annotations/)

## Certificates, Secrets, Identity, and Security

- [cert-manager](https://cert-manager.io/docs/)
- [cert-manager Helm Installation](https://cert-manager.io/docs/installation/helm/)
- [Vault](https://developer.hashicorp.com/vault/docs)
- [External Secrets Operator](https://external-secrets.io/latest/)
- [External Secrets Operator Getting Started](https://external-secrets.io/latest/introduction/getting-started/)
- [authentik](https://docs.goauthentik.io/)
- [Kyverno](https://kyverno.io/docs/)
- [Falco](https://falco.org/docs/)
- [Trivy](https://trivy.dev/latest/docs/)
- [Snyk](https://docs.snyk.io/)
- [GitGuardian](https://docs.gitguardian.com/)

## Storage, Data, and Backups

- [etcd](https://etcd.io/docs/v3.6/)
- [Longhorn](https://longhorn.io/docs/latest/)
- [Longhorn Quick Install](https://longhorn.io/docs/latest/deploy/install/)
- [Velero](https://velero.io/docs/main/)
- [Velero Basic Install](https://velero.io/docs/main/basic-install/)
- [CockroachDB](https://www.cockroachlabs.com/docs/)
- [Redis on Kubernetes](https://redis.io/docs/latest/operate/kubernetes/deployment/quick-start/)
- [NATS](https://docs.nats.io/)

## Autoscaling, Delivery, and GitOps

- [KEDA](https://keda.sh/docs/2.19/)
- [KEDA Concepts](https://keda.sh/docs/2.19/concepts/)
- [Argo CD](https://argo-cd.readthedocs.io/en/stable/)
- [Argo Workflows](https://argoproj.github.io/argo-workflows/)
- [Argo Events](https://argoproj.github.io/argo-events/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [Actions Runner Controller](https://actions-runner-controller.github.io/actions-runner-controller/)

## Observability and Reliability

- [Prometheus](https://prometheus.io/docs/introduction/overview/)
- [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Grafana](https://grafana.com/docs/grafana/latest/)
- [Grafana Loki](https://grafana.com/docs/loki/latest/)
- [Grafana Tempo](https://grafana.com/docs/tempo/latest/)
- [Grafana Pyroscope](https://grafana.com/docs/pyroscope/latest/)
- [Grafana Beyla](https://grafana.com/docs/beyla/latest/)
- [Grafana Alloy](https://grafana.com/docs/alloy/latest/)
- [Grafana Faro](https://grafana.com/docs/grafana-cloud/monitor-applications/frontend-observability/)
- [Grafana k6](https://grafana.com/docs/k6/latest/)
- [Jaeger](https://www.jaegertracing.io/docs/)
- [OpenTelemetry](https://opentelemetry.io/docs/)
- [OpenCost](https://opencost.io/docs/)
- [Chaos Mesh](https://chaos-mesh.org/docs/)

## Policy, Feature Flags, and Multi-Cluster

- [OpenFeature](https://openfeature.dev/docs/reference/intro/)
- [Karmada](https://karmada.io/docs/)

## Infrastructure and Automation Around Kubernetes

- [Ansible Automation Platform Documentation](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6)
- [Terraform](https://developer.hashicorp.com/terraform/docs)
- [Packer](https://developer.hashicorp.com/packer/docs)

## Recommended Learning Order

If you are learning Kubernetes for platform engineering and operations, this order works well:

1. Kubernetes
2. kubectl
3. Helm
4. Kustomize
5. RKE2
6. Cilium
7. cert-manager
8. Argo CD
9. Prometheus and Grafana
10. Kyverno and Falco
11. Vault and External Secrets Operator
12. Crossplane
13. Longhorn or Rook
14. KEDA
15. OpenTelemetry

## Videos

- [Complete Kubernetes Course - From BEGINNER to PRO](https://youtu.be/2T86xAtR6Fo?si=kuK03RyUx28pL4I6)
- [Kubernetes Course – Certified Kubernetes Administrator Exam Preparation](https://youtu.be/Fr9GqFwl6NM?si=YqgXy9rkhllsdbsz)

## Notes

A few of the most useful habits for working with Kubernetes documentation are:

- prefer official docs first
- prefer stable or latest-release docs over random blog posts
- verify version-specific behavior when working with cluster distributions like RKE2
- keep security, networking, storage, and observability docs close together because those topics overlap heavily in real clusters