output "id" {
  description = "Redis cache ID."
  value       = azurerm_redis_cache.this.id
}

output "hostname" {
  description = "Redis hostname."
  value       = azurerm_redis_cache.this.hostname
}
