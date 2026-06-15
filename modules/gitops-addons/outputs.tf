output "flux_configuration_id" {
  description = "Flux configuration ID."
  value       = azurerm_kubernetes_flux_configuration.addons.id
}
