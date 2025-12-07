#

## File tree

```bash
Packer/
├── flatcar/
│   ├── flatcar.json            # Main Packer template for Flatcar on Proxmox
│   ├── variables.json          # Versioning, URLs, checksums
│   ├── http/
│   │   └── ignition.yaml       # Ignition config (served via simple HTTP server)
│   └── scripts/
│       └── post-setup.sh       # Optional config if using script-based provisioning
│
├── proxmox-templates/
│   ├── ubuntu-template.pkr.hcl  # Generalized template that imports ubuntu/vars
│   ├── flatcar-template.pkr.hcl # Generalized template that imports flatcar/vars
│   ├── common.pkr.hcl           # Reusable builders/provisioner defaults
│   └── variables.pkr.hcl        # Global variables (Proxmox API, token, storage)
│
├── scripts/
│   ├── cloud-init/
│   │   ├── meta-data
│   │   ├── user-data
│   │   └── network-config
│   ├── system/
│   │   ├── cleanup.sh          # Remove SSH keys, logs, apt cache
│   │   ├── qemu-guest-agent.sh # Install + enable QGA
│   │   └── base-packages.sh    # Common package install set
│   └── installers/
│       └── ubuntu-autoinstall.sh
│
└── ubuntu/
    ├── ubuntu.pkr.hcl          # Core Ubuntu Packer template
    ├── http/
    │   ├── autoinstall.yaml    # Cloud-init autoinstall config
    │   └── grub.cfg            # Boot automation for Packer ISO boot
    ├── variables.pkr.hcl       # Ubuntu version, ISO URL, checksums
    └── scripts/
        └── post-install.sh     # System setup after autoinstall

```
