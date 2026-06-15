variable "name_prefix" {
  description = "Name prefix for firewall resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Connectivity resource group name."
  type        = string
}

variable "firewall_subnet_id" {
  description = "AzureFirewallSubnet ID."
  type        = string
}

variable "sku_tier" {
  description = "Azure Firewall SKU tier."
  type        = string
  default     = "Standard"
}

variable "availability_zones" {
  description = "Availability zones for zonal resources."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "route_table_id" {
  description = "Optional route table ID used as an enablement marker for default route creation."
  type        = string
  default     = null
}

variable "route_table_name" {
  description = "Optional route table name for default route creation."
  type        = string
  default     = null
}

variable "route_table_resource_group_name" {
  description = "Optional route table resource group name for default route creation."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
