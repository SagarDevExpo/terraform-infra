variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "infrastructure_subnet_id" {
  type    = string
  default = null
}
variable "container_apps" {
  type = map(object({
    image            = string
    cpu              = number
    memory           = string
    min_replicas     = number
    max_replicas     = number
    target_port      = number
    external_enabled = optional(bool, false)
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
