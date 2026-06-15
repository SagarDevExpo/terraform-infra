output "ids" {
  description = "Private endpoint IDs keyed by logical name."
  value       = { for name, endpoint in azurerm_private_endpoint.this : name => endpoint.id }
}
