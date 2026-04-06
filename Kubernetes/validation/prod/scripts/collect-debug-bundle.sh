#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-/tmp/k8s-prod-debug-$(date +%Y%m%d%H%M%S)}"
mkdir -p "${OUT_DIR}"

kubectl get nodes -o wide > "${OUT_DIR}/nodes.txt"
kubectl get events -A --sort-by=.lastTimestamp > "${OUT_DIR}/events.txt"

for ns in kube-system istio-system networking monitoring security gitops helix-ai sinless-games; do
  kubectl -n "${ns}" get pods -o wide > "${OUT_DIR}/${ns}-pods.txt" || true
  kubectl -n "${ns}" get svc,endpoints > "${OUT_DIR}/${ns}-services.txt" || true
done

echo "Debug bundle collected at ${OUT_DIR}"
