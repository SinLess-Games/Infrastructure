#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run "${KUBECTL_BIN}" get nodes -o wide
run "${KUBECTL_BIN}" -n kube-system get pods -o wide
run "${KUBECTL_BIN}" -n kube-system rollout status ds/cilium --timeout=300s
run "${KUBECTL_BIN}" -n kube-system rollout status deploy/cilium-operator --timeout=300s
run "${KUBECTL_BIN}" -n kube-system get sc
run "${KUBECTL_BIN}" -n kube-system get pods -l app=longhorn-manager -o wide
