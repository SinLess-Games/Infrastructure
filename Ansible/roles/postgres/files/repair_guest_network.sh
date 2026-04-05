#!/bin/bash
set -euo pipefail

qm_bin="$(command -v qm || true)"
if [[ -z "$qm_bin" ]]; then
  for candidate in /usr/sbin/qm /usr/bin/qm; do
    if [[ -x "$candidate" ]]; then
      qm_bin="$candidate"
      break
    fi
  done
fi

if [[ -z "$qm_bin" ]]; then
  echo "qm command not found" >&2
  exit 127
fi

vmid="$1"
guest_ip="$2"
guest_cidr="$3"
guest_gateway="$4"
guest_nameservers="$5"

guest_exec() {
  local command_text="$1"
  local result
  local exitcode

  result="$("$qm_bin" guest exec "$vmid" -- /bin/sh -lc "$command_text")"
  exitcode="$(
    printf '%s' "$result" \
      | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data.get("exitcode", ""))'
  )"

  if [[ -z "$exitcode" ]]; then
    echo "Unable to determine guest exec exit code for VM $vmid" >&2
    printf '%s\n' "$result" >&2
    exit 1
  fi

  if [[ "$exitcode" != "0" ]]; then
    echo "Guest command failed for VM $vmid" >&2
    printf '%s\n' "$result" >&2
    exit "$exitcode"
  fi

  printf '%s\n' "$result"
}

iface="$(
  guest_exec "ip -o link show | awk -F': ' '\$2 != \"lo\" {print \$2; exit}'" \
    | python3 -c 'import json,sys; data=json.load(sys.stdin); print((data.get("out-data") or "").strip())'
)"

if [[ -z "$iface" ]]; then
  iface="eth0"
fi

read -r -a nameserver_array <<<"$guest_nameservers"

resolv_lines=()
for nameserver in "${nameserver_array[@]}"; do
  resolv_lines+=("nameserver ${nameserver}")
done
resolv_lines+=("search local.sinlessgamesllc.com")

interfaces_main="$(cat <<EOF
auto lo
iface lo inet loopback

source /etc/network/interfaces.d/*
EOF
)"

interfaces_cloud_init="$(cat <<EOF
auto ${iface}
iface ${iface} inet static
    address ${guest_ip}${guest_cidr}
    gateway ${guest_gateway}
    dns-nameservers ${guest_nameservers}
    dns-search local.sinlessgamesllc.com
EOF
)"

resolv_conf="$(printf '%s\n' "${resolv_lines[@]}")"

disable_cloud_cfg_b64="$(printf '%s' 'network: {config: disabled}' | base64 -w0)"
interfaces_main_b64="$(printf '%s' "$interfaces_main" | base64 -w0)"
interfaces_cloud_init_b64="$(printf '%s' "$interfaces_cloud_init" | base64 -w0)"
resolv_conf_b64="$(printf '%s' "$resolv_conf" | base64 -w0)"

guest_exec "mkdir -p /etc/cloud/cloud.cfg.d /etc/network/interfaces.d"
guest_exec "python3 -c 'import base64,pathlib; pathlib.Path(\"/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg\").write_text(base64.b64decode(\"${disable_cloud_cfg_b64}\").decode())'"
guest_exec "python3 -c 'import base64,pathlib; pathlib.Path(\"/etc/network/interfaces\").write_text(base64.b64decode(\"${interfaces_main_b64}\").decode())'"
guest_exec "python3 -c 'import base64,pathlib; pathlib.Path(\"/etc/network/interfaces.d/50-cloud-init\").write_text(base64.b64decode(\"${interfaces_cloud_init_b64}\").decode())'"
guest_exec "python3 -c 'import base64,pathlib; pathlib.Path(\"/etc/resolv.conf\").write_text(base64.b64decode(\"${resolv_conf_b64}\").decode())'"
guest_exec "ip link set ${iface} up; ip addr flush dev ${iface} scope global || true; ip addr replace ${guest_ip}${guest_cidr} dev ${iface}; ip route replace default via ${guest_gateway} dev ${iface}"
guest_exec "systemctl disable --now fail2ban || true"
guest_exec "systemctl restart ssh || systemctl restart sshd || true"
