#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/phase1-foundation.sh"
"${SCRIPT_DIR}/phase2-istio.sh"
"${SCRIPT_DIR}/phase3-edge-secrets.sh"
"${SCRIPT_DIR}/phase4-observability.sh"
"${SCRIPT_DIR}/phase5-security.sh"
"${SCRIPT_DIR}/phase6-gitops.sh"
"${SCRIPT_DIR}/phase7-data-platform.sh"
"${SCRIPT_DIR}/phase8-examples.sh"
