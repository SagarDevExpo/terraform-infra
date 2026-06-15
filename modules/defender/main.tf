resource "azurerm_security_center_subscription_pricing" "plans" {
  for_each = toset(var.resource_types)

  tier          = var.tier
  resource_type = each.value
}

resource "azurerm_security_center_auto_provisioning" "this" {
  auto_provision = var.auto_provision_log_analytics_agent ? "On" : "Off"
}
