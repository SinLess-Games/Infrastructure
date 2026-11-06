# Upgrade plan (November 2026)

This is a gate list, not an approval to upgrade the cluster. No minor jumps for RKE2, Rancher, Istio, cert-manager, Cilium, Argo CD, or actions-runner-controller are pinned in the hardening branch. Live topology, backups, and each version's compatibility matrix were not verified from this repository.

Do not skip a minor. Do not reuse Helm values blindly across a Cilium upgrade. Back up etcd and the Git revision that is actually synced before each hop. Confirm the running version before applying the next one.

## RKE2 and Rancher

Researcher landing zone, if Rancher stays on the RKE2 local cluster: RKE2 `v1.36.5+rke2r1` and Rancher `2.15.3`. Rancher 2.15 certifies Kubernetes 1.34 through 1.36 and rejects 1.37. `v1.36.6` and `v1.37.2` were prereleases at research time. Recheck those tags before use.

RKE2, one minor at a time, each hop matrix-checked:

1. `v1.31.14+rke2r2` (latest patch on the current 1.31 minor; the repo still pins `v1.31.5+rke2r1`)
2. `v1.32.13+rke2r2`
3. `v1.33.13+rke2r3`
4. `v1.34.12+rke2r1`
5. `v1.35.9+rke2r1`
6. `v1.36.5+rke2r1`

Rancher, one minor at a time, Helm 3.18 or newer. RKE1 is dropped on the way to 2.15. API aggregation changes in 2.15. The repo still pins chart `2.11.3`.

1. `2.11.19` (latest patch on the current 2.11 minor)
2. `2.12.15`
3. `2.13.11`
4. `2.14.7`
5. `2.15.3`

Gate for every hop: backup, version skew against the RKE2 minor that is actually running, and a rollback revision. The 1.31 and 2.11 lines are past upstream end of support. Moving only to the latest patch on those lines does not put them back in support. Those patch pins were not applied here because a control-plane or Rancher patch is not a trivial repo edit.

## Istio

Current charts are `1.24.2`. 1.24 is end of support. Move one minor at a time. Researcher target was `1.30.7` or `1.31.3`, with canary allowing at most one skipped minor only where upstream still documents that canary. Prefer no skipped minors. Re-read the Istio upgrade notes for each hop before changing `platform-helm-applicationset.yaml`.

## cert-manager

Current chart is `v1.16.2`. Path from research:

1. `1.16.5` (latest patch on the current minor)
2. `1.17.4`
3. `1.18.6`
4. `1.19.6` (avoid `1.19.0`; `1.19.6` changes RBAC)
5. `1.20.5`
6. `1.21.3`

Check CRDs and the Kubernetes version at each hop.

## Cilium

Current chart is `1.16.5`. Consecutive only. Do not pass `--reuse-values`.

1. `1.16.19`
2. `1.17.18`
3. `1.18.16`
4. `1.19.10`
5. `1.20.4`

## Argo CD

Current chart is `7.7.11` (application 2.13), which is unsupported. Do not jump straight to chart `10.14.0` / application `3.6.1`. Follow the 2.14.1 and 3.x upgrade guides, and take a backup before 3.0.

`server.insecure` stays `true`. The synced VirtualService sends traffic to port 80, and the DestinationRule is `ISTIO_MUTUAL`. Edge TLS terminates at Istio. Turning `server.insecure` off without moving that route to the Argo HTTPS port will break `argocd.sinlessgames.com`.

The admin bcrypt hash was removed. See [Credential rotation](credential-rotation.md).

## actions-runner-controller

Chart `0.23.7` is the legacy summerwind line. Do not `helm upgrade` it in place to the new controller. Migrate to AutoscalingRunnerSet charts `0.15.1` as a staged cutover. There is no newer 0.23 patch to pin.

## Images changed in this branch

These tags were changed because research named a supported tag and the workload manifest does not require a chart-values migration:

| Image | Was | Now |
| ----- | --- | --- |
| `cloudflare/cloudflared` | `2025.2.1` | `2026.10.7` |
| `otel/opentelemetry-collector-contrib` | `0.116.1` | `0.164.0` |
| `gcr.io/cadvisor/cadvisor` | `v0.52.1` | unchanged |
| `nginxinc/nginx-unprivileged` | `1.27-alpine` | `1.31.7-alpine` |

cAdvisor `v0.60.6` is a GitHub release, and it is not a pullable image. `gcr.io/cadvisor/cadvisor:v0.60.6` returns manifest unknown. `registry.k8s.io/cadvisor:v0.60.6` redirects and then returns the same. The newest tag confirmed on `gcr.io/cadvisor/cadvisor` during this change is `v0.55.1`, which open PR #16 already proposes. This branch leaves `v0.52.1` in place so it does not pin a missing tag and does not duplicate that PR.

A tag existing is not proof the image is free of critical CVEs. Trivy 0.69.3 on 2026-11-06 still reports critical CVE-2026-111497 in `nginxinc/nginx-unprivileged:1.31.7-alpine` (`brotli-libs`). `1.31.7-alpine` is the newest exact patch tag published on Docker Hub for that image at the time of the pin. Cloudflared `2026.10.7` and the OpenTelemetry collector `0.164.0` no longer report the critical IDs found in the previous tags. Each still has one high finding.

`ghcr.io/gethomepage/homepage` stays `v1.5.0`. Research suggested `2.7.0`. That is a major bump. The committed config still uses the v1 files (`settings.yaml`, `kubernetes.yaml`, `proxmox.yaml`, service widgets). Compatibility with 2.7.0 was not verified, so the image was not changed. The known critical findings in `v1.5.0`, including CVE-2025-55182 in Next.js, stay unresolved.

`alpine/k8s` stays `1.30.2` so the client image is not moved independently of the cluster minor.

## Python floors

`Ansible/requirements.txt` and `Docs/requirements.txt` now require:

- `ansible-core>=2.20.7` (CVE-2026-11332; confirm the final 2.20.7 build contains the `2.20.7rc1` fix)
- `cryptography>=50.0.0`
- `urllib3>=2.8.0` (`2.7.0` is still vulnerable)
- `pymdown-extensions>=11.0.1`
- `mkdocs-material>=9.7.7,<10`

`paramiko` stays `4.0.0`. GHSA-r374-rxx8-8654 / CVE-2026-44405 is LOW in OSV, last affected version recorded as 4.0.0, and no fixed release is published. A 5.x bump was not applied. Fix status is unverified.

## Telmate Proxmox provider

Provider version stays `3.0.2-rc07` in both the root module (`Telmate/proxmox`) and the VM module (`telmate/proxmox`). There is no stable 3.0 release. `3.0.2-rc10` is still a prerelease and does not fix the settings below.

| Setting | Change |
| ------- | ------ |
| `pm_debug` | Set to `false` in `Terraform/providers.tf`. Debug logging is safe to turn off. |
| `force_create` | Set to `false` on the production control-plane and worker modules. `true` recycles a VMID that is already in use. |
| `proxmox_tls_insecure` | Left `true` in `Terraform/main.auto.tfvars` and Ansible defaults. Turning it off is not safe until the API certificate is trusted. |

`cpu_type = "host"` is unchanged.

## Open pull requests

This branch overlaps the open dependency PRs. It does not close them.

| PR | Relationship |
| --- | --- |
| #16 Kubernetes image bumps | Conflicts on cloudflared and the OpenTelemetry collector. This branch pins newer tags than #16 for those two. cAdvisor stays `v0.52.1` because `v0.60.6` is not pullable. #16's cAdvisor tag `v0.55.1` is the newest tag confirmed on `gcr.io` and was not copied. #16 also bumps Wazuh, Garage, n8n, busybox, Velero, DFIR-IRIS, homepage, OpenCost, and `alpine/k8s`. Those were left untouched. Homepage in #16 goes to v1.13.2, which is not 2.7.0 and was not adopted. |
| #20 Docs image bumps | Conflicts on `Docs/Dockerfile`. This branch pins `nginxinc/nginx-unprivileged:1.31.7-alpine`. #20 uses the floating `1.31-alpine` tag and also changes the Python base image and the Dockerfile syntax line. Those other #20 edits were not copied. |
| #22 urllib3 to 2.8.0 | Superseded by the `urllib3>=2.8.0` floor. |
| #24 cryptography to 50.0.0 | Superseded by the `cryptography>=50.0.0` floor. |
| #25 ansible-core to 2.20.7 | Superseded by the `ansible-core>=2.20.7` floor. Still confirm the final release contains the rc1 fix. |
| #26 mkdocs-material | Superseded by `mkdocs-material>=9.7.7,<10`. |
| #23 pymdown-extensions | Superseded for the Ansible pin. #23 leaves `Docs/requirements.txt` below 11.0, which keeps CVE-2026-67422 installable. This branch raises that floor to `>=11.0.1`. |
| #21 urllib3 to 2.7.0 and paramiko to 5.0.0 | Do not merge for urllib3. 2.7.0 misses the September 2026 urllib3 advisories. The paramiko major bump is not in this branch. |
| #6, #12, #13, #15, #18, #19 | Not duplicated. Galaxy and GitHub Actions pins are unchanged. |
