# PostgreSQL HA (Patroni + HAProxy + Keepalived)

## Architecture
- 3 Proxmox VMs are provisioned by Terraform module `Terraform/modules/postgres`.
- Ansible drives Terraform through role `Ansible/roles/postgres-deploy`.
- Nodes: `postgres-01`, `postgres-02`, `postgres-03`.
- All nodes run:
  - `etcd` (DCS for Patroni)
  - `Patroni` + PostgreSQL
  - `HAProxy`
  - `keepalived`
- VIP follows the Patroni leader using keepalived health checks.

## Default Network
- VLAN: `20` (configurable with `postgres_vlan_id`)
- Node IPs (default):
  - `postgres-01`: `10.10.20.21`
  - `postgres-02`: `10.10.20.22`
  - `postgres-03`: `10.10.20.23`
- VIP: `10.10.20.50/24`
- Suggested DNS record (manual/out of scope):
  - `postgres-vip.infra.local -> 10.10.20.50`

## Ports
- `22/tcp`: SSH (management CIDRs only)
- `5432/tcp`: PostgreSQL read/write (VIP)
- `5433/tcp`: PostgreSQL read-only (HAProxy)
- `8008/tcp`: Patroni REST API (cluster + management)
- `8404/tcp`: HAProxy stats
- `2379/tcp`: etcd client
- `2380/tcp`: etcd peer
- `112` (IP protocol): VRRP/keepalived

## Variables
Files:
- `Ansible/group_vars/postgres/main.yaml`
- `Ansible/group_vars/postgres/dev.yaml`
- `Ansible/group_vars/postgres/prod.yaml`

Important variables:
- Cluster/VM: `postgres_cluster_name`, `postgres_vm_template_name`, `postgres_vm_count`, `postgres_nodes`
- VM sizing: `postgres_vm_cpu`, `postgres_vm_memory_mb`, `postgres_vm_disk_gb`
- Network: `postgres_vlan_id`, `postgres_network_cidr`, `postgres_gateway`, `postgres_dns_servers`
- VIP: `postgres_vip_ip`, `postgres_vip_cidr`, `postgres_vip_iface`
- Patroni: `patroni.scope`, `patroni.namespace`, `patroni.restapi_port`, `patroni.superuser`, `patroni.replication`

Secrets in `group_vars` are placeholders. Move them to Vault before production.

## Run
```bash
task ansible:deploy-postgres
```

Optional:
- Deploy only (Terraform):
```bash
task ansible:deploy-postgres -- --tags deploy
```
- Configure only (existing VMs):
```bash
task ansible:deploy-postgres -- --tags configure
```
- Production overrides:
```bash
task ansible:deploy-postgres -- -e postgres_environment=prod
```

## Verification
From control node:
```bash
ansible -i Ansible/inventory postgres -m shell -a "patronictl -c /etc/patroni/config.yml list"
ansible -i Ansible/inventory postgres -m shell -a "ip -o -4 addr show dev eth0 | grep 10.10.20.50"
```

From any postgres node:
```bash
PGPASSWORD='<superuser-password>' psql -h 10.10.20.50 -p 5432 -U postgres -d postgres -c 'select 1;'
```

## Failure Test
1. Identify current leader:
```bash
patronictl -c /etc/patroni/config.yml list
```
2. Stop Patroni on the leader:
```bash
sudo systemctl stop patroni
```
3. Watch failover:
```bash
watch -n 2 "patronictl -c /etc/patroni/config.yml list"
```
4. Validate VIP moved and `psql` via VIP still works.
