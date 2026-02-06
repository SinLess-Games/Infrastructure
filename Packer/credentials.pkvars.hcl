# Packer credentials for Proxmox (keep secrets out of repo).
# Set the token via env instead:
#   export PKR_VAR_proxmox_api_token_id="USER@REALM!TOKEN=NAME"
#   export PKR_VAR_proxmox_api_token_secret="TOKEN_SECRET"

# Proxmox API endpoint
proxmox_endpoint = "https://10.10.10.15:8006/api2/json"

# Proxmox API token - split into ID and Secret for security
proxmox_api_token_id = "packer-prov@pve!packer-automation"
proxmox_api_token_secret = "a87e58b8-57db-4c66-8e29-30cafb058f99"

# Default Proxmox node for builds
proxmox_node = "pve-01"

# Storage configuration
# ISO storage: ISOs (Ceph filesystem)
proxmox_iso_storage = "ISOs"

# VM disk storage: vmdisks (LVM thin pool)
proxmox_vm_storage = "VM_Disks"
