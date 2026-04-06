# Production Validation Matrix

| Component | Expected State | Validation Method | Pass Criteria | Remediation Notes |
| --- | --- | --- | --- | --- |
| RKE2 control plane | 3 Ready control plane nodes | `phase1-foundation.sh` | All control plane nodes Ready and etcd healthy | Check `journalctl -u rke2-server`, kube-vip, token, SANs |
| RKE2 workers | 3 Ready workers | `phase1-foundation.sh` | All worker nodes Ready | Check `journalctl -u rke2-agent`, token, server URL |
| Cilium | DaemonSet healthy | `phase1-foundation.sh` | All Cilium pods Ready and Hubble relay healthy | Inspect `cilium status`, CNI config, node routes |
| Longhorn | Default storage available | `phase1-foundation.sh` | PVC bind and test pod attach succeed | Check Longhorn manager logs and disk labels |
| Istio | Control plane and injection healthy | `phase2-istio.sh` | `istiod` healthy, sidecars injected, mTLS passes | Use `istioctl proxy-status`, review PeerAuthentication/Authz |
| Vault ESO | Secret sync healthy | `phase3-edge-secrets.sh` | ExternalSecrets become Ready and target secrets exist | Verify Vault auth role, ClusterSecretStore status |
| cert-manager | Issuer Ready | `phase3-edge-secrets.sh` | ClusterIssuer Ready and certificate issued | Review ACME challenge events and Cloudflare token |
| ExternalDNS | Records reconciled | `phase3-edge-secrets.sh` | DNS records visible in Cloudflare and service annotations reconcile | Check token secret and ownership TXT records |
| cloudflared | Tunnel connected | `phase3-edge-secrets.sh` | Tunnel deployment Ready and logs show connected | Check token secret and tunnel configuration |
| Prometheus stack | Metrics scraping healthy | `phase4-observability.sh` | Targets up and rules healthy | Check ServiceMonitors, scrape errors, storage |
| Loki / Mimir / Tempo / Pyroscope | Object storage backed and reachable | `phase4-observability.sh` | Pods Ready and ingestion endpoints responsive | Validate R2 credentials and bucket access |
| Grafana / Kiali | Dashboards and topology available | `phase4-observability.sh` | Datasources healthy and Kiali shows graph | Check ingress, auth, datasource URLs |
| Kyverno / Falco / Wazuh / Velero | Controls active | `phase5-security.sh` | Policies enforced, Falco signals present, Velero BSL available | Review admission failures, Falco sidekick, backup location |
| Argo CD / Rollouts / ARC | GitOps healthy | `phase6-gitops.sh` | Apps synced, rollout dashboard healthy, runner controller Ready | Check repo access, chart sync, runner secrets |
| CockroachDB / Redis / NATS / Qdrant / n8n | Stateful platform healthy | `phase7-data-platform.sh` | Pods Ready, storage attached, service endpoints pass | Check anti-affinity, PVCs, app logs, probes |
| Examples | Policy and rollout tests healthy | `phase8-examples.sh` | GPU workload, rollout, mesh example, ExternalSecret pass | Use debug bundle if any phase fails |
