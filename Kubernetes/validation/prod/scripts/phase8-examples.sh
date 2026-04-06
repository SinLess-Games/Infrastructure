#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run "${KUBECTL_BIN}" -n helix-ai get pod cuda-vectoradd
run "${KUBECTL_BIN}" -n helix-ai get rollout helix-edge-api
run "${KUBECTL_BIN}" -n sinless-games get deploy,svc mesh-echo
run "${KUBECTL_BIN}" -n helix-ai get externalsecret helix-api-example
