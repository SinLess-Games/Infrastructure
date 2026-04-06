#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run "${KUBECTL_BIN}" -n monitoring get pods
run "${KUBECTL_BIN}" -n monitoring get servicemonitors,podmonitors
run "${KUBECTL_BIN}" -n monitoring get ingress,virtualservice
run "${KUBECTL_BIN}" -n monitoring logs deploy/grafana-alloy --tail=100 || true
