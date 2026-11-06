proxmox_api_url      = "https://10.10.10.14:8006/api2/json"
# Left true on purpose. The Proxmox API certificate is not known to be in
# Terraform's trust store. Turning this off can break applies. Track the
# risk in Docs/Security/upgrade-plan.md. Do not commit the API token.
proxmox_tls_insecure = true

