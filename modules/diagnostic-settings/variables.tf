variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID."
  type        = string
}

variable "targets" {
  description = "Diagnostic targets keyed by logical name."
  type = map(object({
    resource_id    = string
    log_categories = optional(list(string), [])
    enable_metrics = optional(bool, true)
  }))
  default = {}
}
