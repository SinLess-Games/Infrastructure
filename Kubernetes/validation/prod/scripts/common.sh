#!/usr/bin/env bash
set -euo pipefail

KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

run() {
  echo
  echo "==> $*"
  "$@"
}
