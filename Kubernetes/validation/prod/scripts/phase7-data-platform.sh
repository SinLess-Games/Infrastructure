#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run "${KUBECTL_BIN}" -n helix-ai get pods,pvc,svc
run "${KUBECTL_BIN}" -n helix-ai get statefulsets
run "${KUBECTL_BIN}" -n helix-ai describe pvc
run "${KUBECTL_BIN}" -n sinless-games get externalsecret,secret,svc,statefulset,pods
