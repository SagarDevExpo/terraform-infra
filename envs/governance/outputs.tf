output "governance_resource_group_id" {
  description = "Account-level governance resource group ID."
  value       = azurerm_resource_group.governance.id
}

output "dr_pairing_resource_group_ids" {
  description = "DR pairing resource group IDs by primary region."
  value       = { for region, rg in azurerm_resource_group.dr_pairing : region => rg.id }
}
