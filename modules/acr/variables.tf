variable "registry_name" {
  description = "Name of the Container Registry"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region location"
  type        = string
  default     = "eastus"
}

variable "sku" {
  description = "SKU for Container Registry"
  type        = string
  default     = "Basic"
}

variable "admin_enabled" {
  description = "Enable admin user"
  type        = bool
  default     = false
}

variable "georeplication_locations" {
  description = "List of geo-replication locations"
  type        = list(string)
  default     = []
}

variable "public_network_access_enabled" {
  description = "Enable public network access to ACR."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy for Premium ACR."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for Container Registry"
  type        = map(string)
  default = {
    Environment = "production"
    Terraform   = "true"
  }
}
