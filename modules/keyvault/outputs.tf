output "id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.kv.id
}

output "vault_name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.kv.name
}

output "vault_uri" {
  description = "Key Vault URI."
  value       = azurerm_key_vault.kv.vault_uri
}

output "tenant_id" {
  description = "Azure tenant ID."
  value       = data.azurerm_client_config.current.tenant_id
}
