#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run "${KUBECTL_BIN}" -n security get pods
run "${KUBECTL_BIN}" get clusterpolicy
run "${KUBECTL_BIN}" -n security logs ds/wazuh-agent --tail=50 || true
run "${KUBECTL_BIN}" -n security get backupstoragelocations.velero.io -o wide || true
