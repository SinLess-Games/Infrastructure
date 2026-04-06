#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run "${KUBECTL_BIN}" -n security get externalsecret,secretstore,clustersecretstore
run "${KUBECTL_BIN}" -n networking get certificate,certificaterequest,challenge,order
run "${KUBECTL_BIN}" -n networking get deploy cloudflared
run "${KUBECTL_BIN}" -n networking logs deploy/cloudflared --tail=100
