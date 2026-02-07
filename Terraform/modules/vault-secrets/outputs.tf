output "kv_mounts" {
  description = "KV v2 mounts enabled"
  value       = keys(vault_mount.kv)
}

output "engine_mounts" {
  description = "Non-KV engines enabled"
  value       = keys(vault_mount.engine)
}
