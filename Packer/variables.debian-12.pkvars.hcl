# Packer variables for Debian 12 build configuration

# VM Configuration
vm_name     = "debian-12-template"
vm_memory   = 2048  # MB
vm_cores    = 2
vm_sockets  = 1

# Debian Configuration
debian_version = "12"
debian_iso_url = "https://cloudfront.debian.net/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-12.13.0-amd64-netinst.iso"
debian_iso_checksum = "sha256:2b880ffabe36dbe04a662a3125e5ecae4db69d0acce257dd74615bbf165ad76e"
