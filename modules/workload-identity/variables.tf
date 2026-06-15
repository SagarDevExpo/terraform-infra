variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "oidc_issuer_url" { type = string }

variable "identities" {
  description = "Workload identities keyed by app name."
  type = map(object({
    namespace            = string
    service_account_name = string
    role_assignments = optional(list(object({
      scope                = string
      role_definition_name = string
    })), [])
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
