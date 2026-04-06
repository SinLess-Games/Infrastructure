#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run "${KUBECTL_BIN}" -n gitops get applications,applicationsets
run "${KUBECTL_BIN}" -n gitops get pods
run "${KUBECTL_BIN}" -n gitops get rollout
