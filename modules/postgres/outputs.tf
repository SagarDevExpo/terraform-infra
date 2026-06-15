output "id" {
  description = "PostgreSQL flexible server ID."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "fqdn" {
  description = "PostgreSQL flexible server FQDN."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}
