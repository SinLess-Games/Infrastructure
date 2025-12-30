#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ipaddress
import os
import re
from pathlib import Path
from typing import Any, Dict, List, Tuple

import yaml
from jinja2 import Environment, FileSystemLoader, StrictUndefined

ROOT = Path(__file__).resolve().parents[1]
INV = ROOT / "inventory"
TPL = ROOT / "templates"

HTTP_WWW = ROOT / "docker" / "http" / "www"
DNSMASQ_DIR = ROOT / "docker" / "dnsmasq"
DNSMASQ_CONFD = DNSMASQ_DIR / "conf.d"
DNSMASQ_CONF = DNSMASQ_DIR / "dnsmasq.conf"

MAC_RE = re.compile(r"^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$")


def load_yaml(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"Missing required inventory file: {path}")
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if data is None:
        return {}
    if not isinstance(data, dict):
        raise SystemExit(f"Invalid YAML root in {path}: expected mapping/object")
    return data


def sha256_crypt_stub(_: str) -> str:
    # Default: locked password (SSH key login expected)
    return "*"


def _require(obj: dict, key: str, ctx: str) -> Any:
    if key not in obj or obj[key] is None or obj[key] == "":
        raise SystemExit(f"{ctx}: missing required field '{key}'")
    return obj[key]


def _as_list(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(x).strip() for x in value if str(x).strip()]
    return [str(value).strip()] if str(value).strip() else []


def _normalize_mac(mac: str, ctx: str) -> str:
    mac = mac.strip().lower()
    if not MAC_RE.match(mac):
        raise SystemExit(f"{ctx}: invalid mac '{mac}' (expected aa:bb:cc:dd:ee:ff)")
    return mac


def _parse_vlan_range(v: dict, ctx: str) -> Tuple[str, str]:
    # Preferred schema:
    # dhcp_range:
    #   start: 10.0.0.50
    #   end:   10.0.0.200
    if isinstance(v.get("dhcp_range"), dict):
        dr = v["dhcp_range"]
        start = dr.get("start")
        end = dr.get("end")
        if start and end:
            return str(start).strip(), str(end).strip()

    # Back-compat schema: range_start / range_end
    start = v.get("range_start")
    end = v.get("range_end")

    # tolerate accidental lists
    if isinstance(start, list) and start:
        start = start[0]
    if isinstance(end, list) and end:
        end = end[0]

    if start and end:
        return str(start).strip(), str(end).strip()

    raise SystemExit(
        f"{ctx}: missing DHCP range. Provide either "
        f"'dhcp_range: {{start: ..., end: ...}}' or 'range_start' + 'range_end'."
    )


def _ip_in_subnet(ip: str, subnet: str) -> bool:
    try:
        net = ipaddress.ip_network(subnet, strict=False)
        addr = ipaddress.ip_address(ip)
        return addr in net
    except Exception:
        return False


def _require_ip(value: str, name: str) -> str:
    try:
        ipaddress.ip_address(value)
        return value
    except Exception as e:
        raise SystemExit(f"Invalid {name} '{value}': {e}") from e


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--validate", action="store_true", help="Validate inventory only")
    ap.add_argument("--clean", action="store_true", help="Remove previously generated outputs before rendering")
    args = ap.parse_args()

    env = Environment(
        loader=FileSystemLoader(str(TPL)),
        undefined=StrictUndefined,
        trim_blocks=True,
        lstrip_blocks=True,
    )

    # Env / runtime config
    pxeh = os.environ.get("PXE_HTTP_HOST", "pxe.local.sinlessgames.com").strip()
    local_domain = os.environ.get("LOCAL_DOMAIN", "local.sinlessgames.com").strip()
    pxe_server_ip = _require_ip(os.environ.get("PXE_SERVER_IP", "127.0.0.1").strip(), "PXE_SERVER_IP")

    debrel = os.environ.get("DEBIAN_RELEASE", "bookworm").strip()
    arch = os.environ.get("DEBIAN_ARCH", "amd64").strip()

    # Inventory
    vlans_doc = load_yaml(INV / "vlans.yaml")
    nodes_doc = load_yaml(INV / "nodes.yaml")

    vlan_defaults: Dict[str, Any] = vlans_doc.get("defaults", {}) or {}
    node_defaults: Dict[str, Any] = nodes_doc.get("defaults", {}) or {}

    vlans_list = vlans_doc.get("vlans", []) or []
    nodes_list = nodes_doc.get("nodes", []) or []

    if not isinstance(vlans_list, list):
        raise SystemExit("inventory/vlans.yaml: 'vlans' must be a list")
    if not isinstance(nodes_list, list):
        raise SystemExit("inventory/nodes.yaml: 'nodes' must be a list")
    if not vlans_list:
        raise SystemExit("inventory/vlans.yaml: no VLANs defined")
    if not nodes_list:
        raise SystemExit("inventory/nodes.yaml: no nodes defined")

    # Build VLAN map + validate VLANs
    vlan_by_name: Dict[str, Dict[str, Any]] = {}
    for v in vlans_list:
        if not isinstance(v, dict):
            raise SystemExit("inventory/vlans.yaml: each VLAN entry must be a mapping/object")

        name = str(_require(v, "name", "VLAN")).strip()
        ctx = f"VLAN '{name}'"
        if name in vlan_by_name:
            raise SystemExit(f"{ctx}: duplicate VLAN name")

        _require(v, "vlan_id", ctx)
        subnet = str(_require(v, "subnet", ctx)).strip()
        gateway = str(_require(v, "gateway", ctx)).strip()

        try:
            net = ipaddress.ip_network(subnet, strict=False)
        except Exception as e:
            raise SystemExit(f"{ctx}: invalid subnet '{subnet}': {e}") from e

        if not _ip_in_subnet(gateway, subnet):
            raise SystemExit(f"{ctx}: gateway '{gateway}' is not within subnet '{subnet}'")

        range_start, range_end = _parse_vlan_range(v, ctx)
        if not _ip_in_subnet(range_start, subnet) or not _ip_in_subnet(range_end, subnet):
            raise SystemExit(f"{ctx}: DHCP range {range_start}-{range_end} not within subnet '{subnet}'")

        lease = str(v.get("lease") or vlan_defaults.get("lease") or "12h")
        dns_servers = _as_list(v.get("dns_servers") if "dns_servers" in v else vlan_defaults.get("dns_servers"))
        domain = str(v.get("domain") or vlan_defaults.get("domain") or "").strip()

        vlan_by_name[name] = {
            **v,
            "name": name,
            "subnet": subnet,
            "gateway": gateway,
            "lease": lease,
            "dns_servers": dns_servers,
            "domain": domain,
            "_dhcp_start": range_start,
            "_dhcp_end": range_end,
            "_net": net,
        }

    # Validate and normalize Nodes
    seen_hostnames = set()
    seen_macs = set()

    default_vlan = str(node_defaults.get("vlan") or "").strip()
    default_domain = str(node_defaults.get("domain") or vlan_defaults.get("domain") or "local.sinlessgamesllc.com").strip()
    default_boot_disk = str(node_defaults.get("boot_disk") or "/dev/sda")

    for n in nodes_list:
        if not isinstance(n, dict):
            raise SystemExit("inventory/nodes.yaml: each node entry must be a mapping/object")

        hostname = str(_require(n, "hostname", "Node")).strip()
        ctx = f"Node '{hostname}'"

        if hostname in seen_hostnames:
            raise SystemExit(f"{ctx}: duplicate hostname")
        seen_hostnames.add(hostname)

        mac = _normalize_mac(str(_require(n, "mac", ctx)), ctx)
        if mac in seen_macs:
            raise SystemExit(f"{ctx}: duplicate mac '{mac}'")
        seen_macs.add(mac)

        vlan_name = str(n.get("vlan") or default_vlan).strip()
        if not vlan_name:
            raise SystemExit(f"{ctx}: missing vlan and no defaults.vlan is set")
        if vlan_name not in vlan_by_name:
            raise SystemExit(f"{ctx}: references unknown vlan '{vlan_name}'")

        ip = str(_require(n, "ip", ctx)).strip()
        subnet = vlan_by_name[vlan_name]["subnet"]
        if not _ip_in_subnet(ip, subnet):
            raise SystemExit(f"{ctx}: ip '{ip}' is not within vlan '{vlan_name}' subnet '{subnet}'")

        gw = str(n.get("gateway") or vlan_by_name[vlan_name]["gateway"]).strip()
        if not _ip_in_subnet(gw, subnet):
            raise SystemExit(f"{ctx}: gateway '{gw}' is not within vlan '{vlan_name}' subnet '{subnet}'")

        dns = _as_list(n.get("dns"))
        if not dns:
            dns = vlan_by_name[vlan_name]["dns_servers"]

        domain = str(n.get("domain") or vlan_by_name[vlan_name]["domain"] or default_domain).strip()

        # Menu label compatibility
        menu_tag = str(n.get("menu_tag") or node_defaults.get("menu_tag") or "static-ip").strip()

        # Normalize back into node dict for rendering
        n["_mac"] = mac
        n["_vlan"] = vlan_name
        n["_gateway"] = gw
        n["_dns"] = dns
        n["_domain"] = domain
        n["_boot_disk"] = str(n.get("boot_disk") or default_boot_disk).strip()
        n["_menu_tag"] = menu_tag

    if args.validate:
        print("Inventory OK.")
        print(f"- VLANs: {len(vlans_list)}")
        print(f"- Nodes: {len(nodes_list)}")
        return 0

    # Ensure dirs exist
    DNSMASQ_DIR.mkdir(parents=True, exist_ok=True)
    DNSMASQ_CONFD.mkdir(parents=True, exist_ok=True)
    (HTTP_WWW / "ipxe" / "hosts").mkdir(parents=True, exist_ok=True)
    (HTTP_WWW / "preseed" / "generated").mkdir(parents=True, exist_ok=True)
    (HTTP_WWW / "seed").mkdir(parents=True, exist_ok=True)

    if args.clean:
        for conf in DNSMASQ_CONFD.glob("20-vlan-*.conf"):
            conf.unlink(missing_ok=True)
        for p in (HTTP_WWW / "preseed" / "generated").glob("*.cfg"):
            p.unlink(missing_ok=True)
        for p in (HTTP_WWW / "ipxe" / "hosts").glob("*.ipxe"):
            p.unlink(missing_ok=True)

    # Provisioning pubkey
    pubkey_path = ROOT / "secrets" / "provisioning_key.pub"
    if not pubkey_path.exists():
        raise SystemExit("Missing secrets/provisioning_key.pub. Run scripts/gen-shared-key.sh first.")
    provisioning_pubkey = pubkey_path.read_text(encoding="utf-8").strip()

    # Render dnsmasq.conf (top-level config)
    dnsmasq_tpl = env.get_template("dnsmasq.conf.j2")
    DNSMASQ_CONF.write_text(
        dnsmasq_tpl.render(
            PXE_HTTP_HOST=pxeh,
            LOCAL_DOMAIN=local_domain,
            PXE_SERVER_IP=pxe_server_ip,
        ),
        encoding="utf-8",
    )

    # Render dnsmasq VLAN scope snippets from inventory/vlans.yaml
    for conf in DNSMASQ_CONFD.glob("20-vlan-*.conf"):
        conf.unlink(missing_ok=True)

    for name, v in vlan_by_name.items():
        lease = v["lease"]
        dns = v["dns_servers"]
        domain = v["domain"]
        net = v["_net"]
        netmask = str(net.netmask)
        start = v["_dhcp_start"]
        end = v["_dhcp_end"]
        gateway = v["gateway"]

        lines: List[str] = []
        lines.append(f"# Generated from inventory/vlans.yaml ({name})")
        lines.append(f"dhcp-range=set:{name},{start},{end},{netmask},{lease}")
        lines.append(f"dhcp-option=tag:{name},option:router,{gateway}")
        if dns:
            lines.append(f"dhcp-option=tag:{name},option:dns-server,{','.join(dns)}")
        if domain:
            lines.append(f'dhcp-option=tag:{name},option:domain-name,"{domain}"')

        (DNSMASQ_CONFD / f"20-vlan-{name}.conf").write_text("\n".join(lines) + "\n", encoding="utf-8")

    # Render iPXE scripts
    bootstrap_tpl = env.get_template("ipxe.bootstrap.ipxe.j2")
    (HTTP_WWW / "ipxe" / "bootstrap.ipxe").write_text(
        bootstrap_tpl.render(PXE_HTTP_HOST=pxeh),
        encoding="utf-8",
    )

    # Provide nodes to the menu with a "profile" field for template compatibility.
    nodes_for_menu: List[dict] = []
    for n in nodes_list:
        nn = dict(n)
        nn["profile"] = n.get("profile") or n.get("_menu_tag") or "static-ip"
        nodes_for_menu.append(nn)

    menu_tpl = env.get_template("ipxe.menu.ipxe.j2")
    (HTTP_WWW / "ipxe" / "menu.ipxe").write_text(
        menu_tpl.render(
            PXE_HTTP_HOST=pxeh,
            DEBIAN_RELEASE=debrel,
            DEBIAN_ARCH=arch,
            nodes=nodes_for_menu,
        ),
        encoding="utf-8",
    )

    # Templates for per-node assets
    preseed_tpl = env.get_template("preseed.bookworm.cfg.j2")
    user_tpl = env.get_template("cloud-init.user-data.j2")
    meta_tpl = env.get_template("cloud-init.meta-data.j2")

    # Render per-node preseed + cloud-init seed
    for n in nodes_list:
        hostname = n["hostname"]
        vlan_name = n["_vlan"]
        v = vlan_by_name[vlan_name]
        domain = n["_domain"]

        boot_disk = n["_boot_disk"]
        root_pw = str(n.get("root_password_crypted") or sha256_crypt_stub(hostname))

        seed_base = f"http://{pxeh}/seed/{hostname}"
        seed_meta_url = f"{seed_base}/meta-data"
        seed_user_url = f"{seed_base}/user-data"

        node_json = {
            "hostname": hostname,
            "fqdn": f"{hostname}.{domain}" if domain else hostname,
            "mac": n["_mac"],
            "vlan": vlan_name,
            "ip": n["ip"],
            "gateway": n["_gateway"],
            "dns": n["_dns"],
            "domain": domain,
            "subnet": v["subnet"],
            "pxe_http_host": pxeh,
            "debian_release": debrel,
            "debian_arch": arch,
        }

        preseed = preseed_tpl.render(
            hostname=hostname,
            domain=domain,
            boot_disk=boot_disk,
            root_password_crypted=root_pw,
            seed_meta_url=seed_meta_url,
            seed_user_url=seed_user_url,
        )
        (HTTP_WWW / "preseed" / "generated" / f"{hostname}.cfg").write_text(preseed, encoding="utf-8")

        seed_dir = HTTP_WWW / "seed" / hostname
        seed_dir.mkdir(parents=True, exist_ok=True)

        (seed_dir / "meta-data").write_text(
            meta_tpl.render(hostname=hostname),
            encoding="utf-8",
        )
        (seed_dir / "user-data").write_text(
            user_tpl.render(
                hostname=hostname,
                provisioning_pubkey=provisioning_pubkey,
                profile_json=node_json,
            ),
            encoding="utf-8",
        )

        (HTTP_WWW / "ipxe" / "hosts" / f"{hostname}.ipxe").write_text(
            f"#!ipxe\nchain http://{pxeh}/ipxe/menu.ipxe || exit\n",
            encoding="utf-8",
        )

    # Generic preseed + seed (useful for ad-hoc installs)
    generic_domain = str(vlan_defaults.get("domain") or default_domain or "local.sinlessgamesllc.com")
    generic = preseed_tpl.render(
        hostname="debian",
        domain=generic_domain,
        boot_disk="/dev/sda",
        root_password_crypted=sha256_crypt_stub("debian"),
        seed_meta_url=f"http://{pxeh}/seed/generic/meta-data",
        seed_user_url=f"http://{pxeh}/seed/generic/user-data",
    )
    (HTTP_WWW / "preseed" / "bookworm.cfg").write_text(generic, encoding="utf-8")

    (HTTP_WWW / "seed" / "generic").mkdir(parents=True, exist_ok=True)
    (HTTP_WWW / "seed" / "generic" / "meta-data").write_text(
        "instance-id: generic\nlocal-hostname: debian\n",
        encoding="utf-8",
    )
    (HTTP_WWW / "seed" / "generic" / "user-data").write_text("#cloud-config\n", encoding="utf-8")

    print("Rendered OK.")
    print(f"- HTTP root: {HTTP_WWW}")
    print(f"- dnsmasq scopes: {DNSMASQ_CONFD}")
    print(f"- PXE_HTTP_HOST: {pxeh}")
    print(f"- LOCAL_DOMAIN: {local_domain}")
    print(f"- PXE_SERVER_IP: {pxe_server_ip}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
