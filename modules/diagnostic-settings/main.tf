resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.targets

  name                       = "${each.key}-diagnostics"
  target_resource_id         = each.value.resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = each.value.enable_metrics
  }
}
