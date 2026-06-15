output "client_ids" {
  description = "Managed identity client IDs keyed by name."
  value       = { for name, identity in azurerm_user_assigned_identity.this : name => identity.client_id }
}

output "principal_ids" {
  description = "Managed identity principal IDs keyed by name."
  value       = { for name, identity in azurerm_user_assigned_identity.this : name => identity.principal_id }
}
