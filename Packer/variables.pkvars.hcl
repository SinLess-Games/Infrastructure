# Packer variables for Debian 13 build configuration

# VM Configuration
vm_name     = "debian-13-template"
vm_memory   = 2048  # MB
vm_cores    = 2
vm_sockets  = 1

# Debian Configuration
debian_version = "13"
debian_iso_url = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"
debian_iso_checksum = "sha256:0b813535dd76f2ea96eff908c65e8521512c92a0631fd41c95756ffd7d4896dc"
