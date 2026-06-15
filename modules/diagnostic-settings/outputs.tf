output "ids" {
  description = "Diagnostic setting IDs."
  value       = { for name, setting in azurerm_monitor_diagnostic_setting.this : name => setting.id }
}
