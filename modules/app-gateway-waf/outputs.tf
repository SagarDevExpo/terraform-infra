output "id" {
  description = "Application Gateway ID."
  value       = azurerm_application_gateway.this.id
}

output "waf_policy_id" {
  description = "WAF policy ID."
  value       = azurerm_web_application_firewall_policy.this.id
}

output "public_ip_address" {
  description = "Application Gateway public IP address."
  value       = azurerm_public_ip.this.ip_address
}
