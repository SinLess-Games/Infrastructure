# Packer variables for Debian 13 build configuration

# VM Configuration
vm_name     = "debian-13-template"
vm_memory   = 2048  # MB
vm_cores    = 2
vm_sockets  = 1

# Debian Configuration
debian_version = "13"
debian_iso_url = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.3.0-amd64-netinst.iso"
debian_iso_checksum = "sha256:c9f09d24b7e834e6834f2ffa565b33d6f1f540d04bd25c79ad9953bc79a8ac02"
