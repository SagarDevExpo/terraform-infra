variable "name_prefix" {
  description = "Prefix for landing-zone resources."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription where landing-zone policies are assigned."
  type        = string
}

variable "location" {
  description = "Primary Azure region."
  type        = string
}

variable "hub_address_space" {
  description = "Primary hub VNet CIDR ranges."
  type        = list(string)
}

variable "firewall_subnet_prefix" {
  description = "CIDR for AzureFirewallSubnet."
  type        = string
}

variable "shared_services_subnet_prefix" {
  description = "CIDR for shared services subnet."
  type        = string
}

variable "private_dns_zones" {
  description = "Private DNS zones for platform services."
  type        = list(string)
}

variable "required_tags" {
  description = "Required Azure resource tags."
  type        = list(string)
  default     = ["Application", "Environment", "ManagedBy", "Owner", "CostCenter", "DataClass"]
}

variable "log_retention_days" {
  description = "Log Analytics retention days."
  type        = number
  default     = 90
}

variable "availability_zones" {
  description = "Availability zones for zone-aware shared resources."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
