output "id" {
  description = "ACR resource ID."
  value       = azurerm_container_registry.acr.id
}

output "registry_name" {
  description = "Container Registry name."
  value       = azurerm_container_registry.acr.name
}

output "registry_login_server" {
  description = "Container Registry login server."
  value       = azurerm_container_registry.acr.login_server
}
