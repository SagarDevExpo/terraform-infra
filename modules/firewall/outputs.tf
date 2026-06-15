output "id" {
  description = "Azure Firewall ID."
  value       = azurerm_firewall.this.id
}

output "private_ip_address" {
  description = "Azure Firewall private IP address."
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "policy_id" {
  description = "Azure Firewall Policy ID."
  value       = azurerm_firewall_policy.this.id
}
