// Packer/proxmox-templates/variables.auto.pkrvars.hcl
proxmox_url               = "https://pve.yourdomain.example:8006/api2/json"
proxmox_api_token_id      = "packer@pve!mytoken"
proxmox_api_token_secret  = "YOUR_SECRET_TOKEN_HERE"

proxmox_node              = "pve-node-01"
proxmox_storage_pool      = "local-lvm"
proxmox_template_pool     = "local-lvm"

# Optional: skip TLS verify (useful for self-signed certs)
insecure_skip_tls_verify  = false

# VM defaults
vm_memory   = 2048
vm_cores    = 2
vm_disk_size = "8G"

vm_network_bridge = "vmbr0"

# SSH settings for the builder / provisioner
ssh_username           = "sinless777"
ssh_private_key_file   = "~/.ssh/id_ed25565"
ssh_timeout            = "30m"


# Flatcar Linux image settings
flatcar_img_url       = "https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_image.bin.bz2"
flatcar_img_checksum  = "sha256:YOUR_FLATCAR_IMAGE_CHECKSUM_HERE"
flatcar_template_name = "flatcar-template"

