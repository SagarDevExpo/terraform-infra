variable "name_prefix" {
  description = "Name prefix for all resources"
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

variable "dns_prefix" {
  description = "DNS prefix for AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.0"
}

variable "aks_subnet_id" {
  description = "ID of the subnet for AKS"
  type        = string
}

variable "acr_id" {
  description = "ID of the ACR for AKS"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault for AKS"
  type        = string
}

variable "admin_group_object_ids" {
  description = "List of admin group object IDs for Azure AD RBAC"
  type        = list(string)
  default     = []
}

variable "system_node_pool" {
  description = "System node pool configuration"
  type = object({
    vm_size         = string
    node_count      = number
    os_disk_size_gb = number
  })
  default = {
    vm_size         = "Standard_B2s"
    node_count      = 3
    os_disk_size_gb = 30
  }
}

variable "user_node_pools" {
  description = "User node pools configuration"
  type = map(object({
    vm_size         = string
    os_disk_size_gb = number
    min_count       = number
    max_count       = number
    node_labels     = map(string)
    node_taints     = list(string)
    priority        = string
  }))
  default = {
    workload = {
      vm_size         = "Standard_B2s"
      os_disk_size_gb = 30
      min_count       = 1
      max_count       = 10
      node_labels     = {}
      node_taints     = []
      priority        = "Regular"
    }
  }
}

variable "service_cidr" {
  description = "Service CIDR for AKS"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP for AKS"
  type        = string
  default     = "10.0.0.10"
}

variable "network_plugin" {
  description = "Network plugin for AKS"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy for AKS"
  type        = string
  default     = "azure"
}

variable "outbound_type" {
  description = "Outbound type for AKS"
  type        = string
  default     = "loadBalancer"
}

variable "availability_zones" {
  description = "Availability zones for AKS"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "log_retention_days" {
  description = "Log retention days for Log Analytics"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "terraform-infra"
    ManagedBy   = "platform-engineering"
    Owner       = "platform-team"
  }
}
