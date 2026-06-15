output "vnet_id" {
  description = "Spoke VNet ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Spoke VNet name."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Subnet IDs keyed by subnet name."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "route_table_id" {
  description = "Route table ID."
  value       = try(azurerm_route_table.this[0].id, null)
}

output "route_table_name" {
  description = "Route table name."
  value       = try(azurerm_route_table.this[0].name, null)
}
