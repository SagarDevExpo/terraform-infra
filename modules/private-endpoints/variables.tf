variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }

variable "private_endpoints" {
  description = "Private endpoints keyed by logical name."
  type = map(object({
    resource_id          = string
    subresource_names    = list(string)
    private_dns_zone_ids = optional(list(string), [])
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
