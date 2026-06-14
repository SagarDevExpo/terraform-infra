variable "name_prefix" {
  description = "Prefix for VNet resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for VNet resources."
  type        = string
}

variable "address_space" {
  description = "Spoke VNet CIDR ranges."
  type        = list(string)
}

variable "subnets" {
  description = "Workload spoke subnets."
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
  }))
}

variable "create_route_table" {
  description = "Create a route table for spoke subnets."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
