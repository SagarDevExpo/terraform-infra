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

# true = Standard/Basic SKU (public access allowed, firewalled by private endpoints).
# false = requires Premium SKU; completely disables public access at the Azure level.
variable "public_network_access_enabled" {
  description = "Enable public network access to ACR. Set to false only when using Premium SKU."
  type        = bool
  default     = true # Standard SKU (used by default) does not support false
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
