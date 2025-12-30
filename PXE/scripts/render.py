#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ipaddress
import json
import os
import re
import shutil
from pathlib import Path
from typing import Any, Dict, List, Optional

import yaml
from jinja2 import Environment, FileSystemLoader, StrictUndefined

ROOT = Path(__file__).resolve().parents[1]
INV = ROOT / "inventory"
TPL = ROOT / "templates"

HTTP_WWW = ROOT / "docker" / "http" / "www"
TFTP_ROOT = ROOT / "docker" / "tftp"

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


def _require_ip(value: str, name: str, ctx: str) -> str:
    try:
        ipaddress.ip_address(value)
        return value
    except Exception as e:
        raise SystemExit(f"{ctx}: invalid {name} '{value}': {e}") from e


def _maybe_subnet(value: Optional[str], ctx: str) -> Optional[ipaddress.IPv4Network | ipaddress.IPv6Network]:
    if not value:
        return None
    try:
        return ipaddress.ip_network(value, strict=False)
    except Exception as e:
        raise SystemExit(f"{ctx}: invalid subnet '{value}': {e}") from e


def _in_subnet(ip: str, net: ipaddress._BaseNetwork) -> bool:
    return ipaddress.ip_address(ip) in net


def sha256_crypt_stub(_: str) -> str:
    # Default: locked password (SSH key login expected)
    return "*"


def ensure_dir(p: Path) -> None:
    p.mkdir(parents=True, exist_ok=True)


def rm_tree_if_exists(p: Path) -> None:
    if p.exists():
        shutil.rmtree(p)


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


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

    def _tojson(value: Any, indent: int = 0, **_: Any) -> str:
        return json.dumps(value, indent=indent, sort_keys=True)

    env.filters["tojson"] = _tojson

    # -------------------------------------------------------------------------
    # Runtime config
    #
    # PXE_HTTP_HOST: FQDN used for DISPLAY in menus/docs (may require DNS)
    # PXE_CHAIN_HOST: IP/host used for DOWNLOAD URLs (avoid DNS dependency)
    # -------------------------------------------------------------------------
    pxe_http_host = os.environ.get("PXE_HTTP_HOST", "pxe.local.sinlessgames.com").strip()

    pxe_server_ip = os.environ.get("PXE_SERVER_IP", "127.0.0.1").strip()
    pxe_chain_host_raw = os.environ.get("PXE_CHAIN_HOST", "").strip() or pxe_server_ip
    pxe_chain_host = _require_ip(pxe_chain_host_raw, "PXE_CHAIN_HOST", "Runtime config")

    debrel = os.environ.get("DEBIAN_RELEASE", "bookworm").strip()
    arch = os.environ.get("DEBIAN_ARCH", "amd64").strip()

    # Inventory
    nodes_doc = load_yaml(INV / "nodes.yaml")
    node_defaults: Dict[str, Any] = nodes_doc.get("defaults", {}) or {}
    nodes_list = nodes_doc.get("nodes", []) or []

    if not isinstance(nodes_list, list):
        raise SystemExit("inventory/nodes.yaml: 'nodes' must be a list")
    if not nodes_list:
        raise SystemExit("inventory/nodes.yaml: no nodes defined")

    # Optional subnet validation
    default_subnet_raw = str(node_defaults.get("subnet") or "").strip()
    default_subnet = _maybe_subnet(default_subnet_raw, "nodes.yaml defaults") if default_subnet_raw else None

    default_gateway = str(node_defaults.get("gateway") or "").strip()
    default_dns = _as_list(node_defaults.get("dns"))
    default_domain = str(node_defaults.get("domain") or "local.sinlessgames.com").strip()
    default_boot_disk = str(node_defaults.get("boot_disk") or "/dev/sda").strip()
    default_menu_tag = str(node_defaults.get("menu_tag") or "static-ip").strip()

    # Validate and normalize nodes
    seen_hostnames: set[str] = set()
    seen_macs: set[str] = set()
    seen_ips: set[str] = set()

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

        ip = _require_ip(str(_require(n, "ip", ctx)).strip(), "ip", ctx)
        if ip in seen_ips:
            raise SystemExit(f"{ctx}: duplicate ip '{ip}'")
        seen_ips.add(ip)

        gateway = str(n.get("gateway") or default_gateway).strip()
        if not gateway:
            raise SystemExit(f"{ctx}: missing gateway and defaults.gateway is not set")
        gateway = _require_ip(gateway, "gateway", ctx)

        dns = _as_list(n.get("dns")) or default_dns
        if not dns:
            raise SystemExit(f"{ctx}: missing dns and defaults.dns is not set")
        for d in dns:
            _require_ip(str(d), "dns", ctx)

        domain = str(n.get("domain") or default_domain).strip()
        if not domain:
            raise SystemExit(f"{ctx}: domain resolved to empty")

        if default_subnet:
            if not _in_subnet(ip, default_subnet):
                raise SystemExit(f"{ctx}: ip '{ip}' not in defaults.subnet '{default_subnet}'")
            if not _in_subnet(gateway, default_subnet):
                raise SystemExit(f"{ctx}: gateway '{gateway}' not in defaults.subnet '{default_subnet}'")

        n["_mac"] = mac
        n["_ip"] = ip
        n["_gateway"] = gateway
        n["_dns"] = dns
        n["_domain"] = domain
        n["_boot_disk"] = str(n.get("boot_disk") or default_boot_disk).strip()
        n["_menu_tag"] = str(n.get("menu_tag") or default_menu_tag).strip()

    if args.validate:
        print("Inventory OK.")
        print(f"- Nodes: {len(nodes_list)}")
        return 0

    # Output dirs
    ensure_dir(HTTP_WWW / "ipxe" / "hosts")
    ensure_dir(HTTP_WWW / "ipxe" / "macs")
    ensure_dir(HTTP_WWW / "preseed" / "generated")
    ensure_dir(HTTP_WWW / "seed")
    ensure_dir(TFTP_ROOT)

    if args.clean:
        for p in (HTTP_WWW / "preseed" / "generated").glob("*.cfg"):
            p.unlink(missing_ok=True)
        for p in (HTTP_WWW / "ipxe" / "hosts").glob("*.ipxe"):
            p.unlink(missing_ok=True)
        for p in (HTTP_WWW / "ipxe" / "macs").glob("*.ipxe"):
            p.unlink(missing_ok=True)
        for n in nodes_list:
            rm_tree_if_exists(HTTP_WWW / "seed" / n["hostname"])

    # Provisioning pubkey
    pubkey_path = ROOT / "secrets" / "provisioning_key.pub"
    if not pubkey_path.exists():
        raise SystemExit("Missing secrets/provisioning_key.pub. Run scripts/gen-shared-key.sh first.")
    provisioning_pubkey = pubkey_path.read_text(encoding="utf-8").strip()

    # Downloads always use CHAIN HOST (IP)
    pxe_http_render_host = pxe_chain_host

    # Render HTTP iPXE scripts (templates)
    bootstrap_tpl = env.get_template("ipxe.bootstrap.ipxe.j2")
    _write_text(
        HTTP_WWW / "ipxe" / "bootstrap.ipxe",
        bootstrap_tpl.render(
            PXE_HTTP_HOST=pxe_http_render_host,
            PXE_HTTP_DISPLAY_HOST=pxe_http_host,
            PXE_CHAIN_HOST=pxe_chain_host,
        ),
    )

    nodes_for_menu: List[dict] = []
    for n in nodes_list:
        nn = dict(n)
        nn["profile"] = n.get("profile") or n.get("_menu_tag") or "static-ip"
        nodes_for_menu.append(nn)

    menu_tpl = env.get_template("ipxe.menu.ipxe.j2")
    _write_text(
        HTTP_WWW / "ipxe" / "menu.ipxe",
        menu_tpl.render(
            PXE_HTTP_HOST=pxe_http_render_host,
            PXE_HTTP_DISPLAY_HOST=pxe_http_host,
            PXE_CHAIN_HOST=pxe_chain_host,
            DEBIAN_RELEASE=debrel,
            DEBIAN_ARCH=arch,
            nodes=nodes_for_menu,
        ),
    )

    # Templates for per-node assets
    preseed_tpl = env.get_template("preseed.bookworm.cfg.j2")
    user_tpl = env.get_template("cloud-init.user-data.j2")
    meta_tpl = env.get_template("cloud-init.meta-data.j2")

    # Per-node: preseed + seed + host ipxe + mac ipxe
    for n in nodes_list:
        hostname = n["hostname"]
        domain = n["_domain"]
        fqdn = f"{hostname}.{domain}" if domain else hostname

        boot_disk = n["_boot_disk"]
        root_pw = str(n.get("root_password_crypted") or sha256_crypt_stub(hostname))

        seed_base = f"http://{pxe_http_render_host}/seed/{hostname}"
        seed_meta_url = f"{seed_base}/meta-data"
        seed_user_url = f"{seed_base}/user-data"

        node_json = {
            "hostname": hostname,
            "fqdn": fqdn,
            "mac": n["_mac"],
            "ip": n["_ip"],
            "gateway": n["_gateway"],
            "dns": n["_dns"],
            "domain": domain,
            "pxe_http_display_host": pxe_http_host,
            "pxe_http_host": pxe_http_render_host,
            "pxe_chain_host": pxe_chain_host,
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
        _write_text(HTTP_WWW / "preseed" / "generated" / f"{hostname}.cfg", preseed)

        seed_dir = HTTP_WWW / "seed" / hostname
        ensure_dir(seed_dir)

        _write_text(seed_dir / "meta-data", meta_tpl.render(hostname=hostname, fqdn=fqdn))
        _write_text(
            seed_dir / "user-data",
            user_tpl.render(
                hostname=hostname,
                provisioning_pubkey=provisioning_pubkey,
                profile_json=node_json,
            ),
        )

        # Host ipxe (optional)
        _write_text(
            HTTP_WWW / "ipxe" / "hosts" / f"{hostname}.ipxe",
            f"#!ipxe\nchain http://{pxe_http_render_host}/ipxe/menu.ipxe || exit\n",
        )

        # Per-MAC hands-free installer (NO MENU)
        # UniFi can be configured to chain to:
        #   http://<PXE_CHAIN_HOST>/ipxe/macs/${net0/mac:hexhyp}.ipxe
        mac_hyp = n["_mac"].replace(":", "-")
        mac_ipxe = (
            "#!ipxe\n"
            "dhcp || shell\n"
            f"set pxe-http http://{pxe_http_render_host}\n"
            f"set pxe-label {pxe_http_host}\n"
            f"set debrel {debrel}\n"
            f"set arch {arch}\n"
            "set debian-kernel ${pxe-http}/debian/${debrel}/${arch}/linux\n"
            "set debian-initrd ${pxe-http}/debian/${debrel}/${arch}/initrd.gz\n"
            f"set preseed ${pxe-http}/preseed/generated/{hostname}.cfg\n"
            "kernel ${debian-kernel} auto=true priority=critical url=${preseed} ---\n"
            "initrd ${debian-initrd}\n"
            "boot\n"
        )
        _write_text(HTTP_WWW / "ipxe" / "macs" / f"{mac_hyp}.ipxe", mac_ipxe)

    # Generic preseed + seed
    generic_domain = default_domain or "local.sinlessgames.com"
    generic = preseed_tpl.render(
        hostname="debian",
        domain=generic_domain,
        boot_disk="/dev/sda",
        root_password_crypted=sha256_crypt_stub("debian"),
        seed_meta_url=f"http://{pxe_http_render_host}/seed/generic/meta-data",
        seed_user_url=f"http://{pxe_http_render_host}/seed/generic/user-data",
    )
    _write_text(HTTP_WWW / "preseed" / "bookworm.cfg", generic)

    ensure_dir(HTTP_WWW / "seed" / "generic")
    _write_text(HTTP_WWW / "seed" / "generic" / "meta-data", "instance-id: generic\nlocal-hostname: debian\n")
    _write_text(HTTP_WWW / "seed" / "generic" / "user-data", "#cloud-config\n")

    # TFTP autoexec: jump to bootstrap (IP via next-server)
    _write_text(
        TFTP_ROOT / "autoexec.ipxe",
        "#!ipxe\n"
        "dhcp || shell\n"
        "chain http://${next-server}/ipxe/bootstrap.ipxe || shell\n",
    )

    print("Rendered OK.")
    print(f"- HTTP root: {HTTP_WWW}")
    print(f"- TFTP root: {TFTP_ROOT}")
    print(f"- PXE_HTTP_HOST (display): {pxe_http_host}")
    print(f"- PXE_CHAIN_HOST (downloads): {pxe_chain_host}")
    print()
    print("Hands-free endpoint (use in DHCP/UniFi bootfile when possible):")
    print(f"- http://{pxe_http_render_host}/ipxe/macs/${{net0/mac:hexhyp}}.ipxe")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
