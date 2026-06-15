output "id" {
  description = "NAT Gateway ID."
  value       = azurerm_nat_gateway.this.id
}

output "public_ip_address" {
  description = "NAT public IP address."
  value       = azurerm_public_ip.this.ip_address
}
