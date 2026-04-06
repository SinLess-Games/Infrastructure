#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run "${KUBECTL_BIN}" -n istio-system get pods -o wide
run "${KUBECTL_BIN}" -n istio-system get peerauthentication,authorizationpolicy,destinationrule,gateway
run "${KUBECTL_BIN}" -n helix-ai get pods
run "${KUBECTL_BIN}" -n sinless-games get pods
