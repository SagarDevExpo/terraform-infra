output "enabled_resource_types" {
  description = "Defender resource types enabled."
  value       = [for plan in azurerm_security_center_subscription_pricing.plans : plan.resource_type]
}
