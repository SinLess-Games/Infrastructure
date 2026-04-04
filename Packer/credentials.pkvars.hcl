# Packer credentials for Proxmox (keep secrets out of repo).
# Set the token via env instead:
#   export PKR_VAR_proxmox_api_token_id="USER@REALM!TOKEN=NAME"
#   export PKR_VAR_proxmox_api_token_secret="TOKEN_SECRET"

# Proxmox API endpoint
proxmox_endpoint = "https://10.10.10.14:8006/api2/json"

# Proxmox API token - split into ID and Secret for security
proxmox_api_token_id = "packer-prov@pve!packer-automation"
proxmox_api_token_secret = "9bbf3c3a-19cf-4343-9a73-00e1f4eb3097"

# Default Proxmox node for builds (must be Proxmox node name, not IP)
proxmox_node = "pve-01"

# Storage configuration
# ISO storage: ISOs (Ceph filesystem)
proxmox_iso_storage = "local"

# VM disk storage: vmdisks (LVM thin pool)
proxmox_vm_storage = "vm_disks_01"
