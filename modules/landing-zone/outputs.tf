output "management_resource_group_id" {
  description = "Management resource group ID."
  value       = azurerm_resource_group.management.id
}

output "management_resource_group_name" {
  description = "Management resource group name."
  value       = azurerm_resource_group.management.name
}

output "connectivity_resource_group_id" {
  description = "Connectivity resource group ID."
  value       = azurerm_resource_group.connectivity.id
}

output "connectivity_resource_group_name" {
  description = "Connectivity resource group name."
  value       = azurerm_resource_group.connectivity.name
}

output "hub_vnet_id" {
  description = "Primary hub VNet ID."
  value       = azurerm_virtual_network.hub.id
}

output "private_dns_zone_ids" {
  description = "Private DNS zone IDs keyed by zone name."
  value       = { for name, zone in azurerm_private_dns_zone.zones : name => zone.id }
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID."
  value       = azurerm_log_analytics_workspace.platform.id
}

output "waf_public_ip_id" {
  description = "WAF public IP resource ID."
  value       = azurerm_public_ip.waf.id
}

output "waf_public_ip_address" {
  description = "WAF public IP address."
  value       = azurerm_public_ip.waf.ip_address
}

output "management_policy_assignment_ids" {
  description = "Management policy assignment IDs."
  value = {
    require_tags    = azurerm_subscription_policy_assignment.require_tags.id
    deny_public_aks = azurerm_subscription_policy_assignment.deny_public_aks.id
  }
}
