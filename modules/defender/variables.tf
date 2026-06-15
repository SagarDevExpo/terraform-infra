variable "tier" {
  description = "Defender plan tier."
  type        = string
  default     = "Standard"
}

variable "resource_types" {
  description = "Defender resource types to enable."
  type        = list(string)
  default     = ["VirtualMachines", "Containers", "KeyVaults", "Arm", "AppServices", "SqlServers"]
}

variable "auto_provision_log_analytics_agent" {
  description = "Enable Defender auto provisioning."
  type        = bool
  default     = false
}
