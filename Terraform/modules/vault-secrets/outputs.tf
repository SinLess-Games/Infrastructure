output "kv_mounts" {
  description = "KV v2 mounts enabled"
  value       = keys(vault_mount.kv)
}

output "engine_mounts" {
  description = "Non-KV engines enabled"
  value       = keys(vault_mount.engine)
}

output "secrets_created" {
  description = "Secrets created in the 'secrets' KV mount"
  value       = keys(vault_generic_secret.secrets)
  sensitive   = true
}
