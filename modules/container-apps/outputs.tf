output "environment_id" {
  description = "Container Apps environment ID."
  value       = azurerm_container_app_environment.this.id
}

output "app_ids" {
  description = "Container App IDs."
  value       = { for name, app in azurerm_container_app.apps : name => app.id }
}
