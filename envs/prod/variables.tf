variable "name_prefix" {
  description = "Environment/account-region-specific resource name prefix."
  type        = string
}

variable "subscription_id" {
  description = "Prod Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "location" {
  description = "Primary Azure region for prod resources."
  type        = string
  default     = "eastus"
}

variable "enabled_modules" {
  description = "Controls phased account onboarding. Disabling an already-created module can plan destruction and should be done only through an approved decommission flow."
  type = object({
    landing_zone = bool
    vnet         = bool
    acr          = bool
    keyvault     = bool
    aks          = bool
  })

  validation {
    condition = (
      !var.enabled_modules.aks ||
      (
        var.enabled_modules.landing_zone &&
        var.enabled_modules.vnet &&
        var.enabled_modules.acr &&
        var.enabled_modules.keyvault
      )
    )
    error_message = "AKS requires landing_zone, vnet, acr, and keyvault to be enabled."
  }

  validation {
    condition = (
      !(
        var.enabled_modules.vnet ||
        var.enabled_modules.acr ||
        var.enabled_modules.keyvault
      ) ||
      var.enabled_modules.landing_zone
    )
    error_message = "Platform modules require landing_zone to be enabled."
  }
}

variable "hub_address_space" {
  description = "Landing-zone hub VNet address space."
  type        = list(string)
}

variable "firewall_subnet_prefix" {
  description = "AzureFirewallSubnet CIDR."
  type        = string
}

variable "shared_services_subnet_prefix" {
  description = "Shared services subnet CIDR."
  type        = string
}

variable "private_dns_zones" {
  description = "Private DNS zones for platform services."
  type        = list(string)
}

variable "spoke_address_space" {
  description = "Workload spoke VNet address space."
  type        = list(string)
}

variable "subnets" {
  description = "Workload spoke subnets."
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
  }))
}

variable "acr_name" {
  description = "Globally unique ACR name."
  type        = string
}

variable "key_vault_name" {
  description = "Globally unique Key Vault name."
  type        = string
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
}

variable "aks_admin_group_object_ids" {
  description = "Entra ID group object IDs for AKS admin access."
  type        = list(string)
  default     = []
}

variable "system_node_pool" {
  description = "AKS system node pool."
  type = object({
    vm_size         = string
    node_count      = number
    os_disk_size_gb = number
  })
}

variable "user_node_pools" {
  description = "AKS user node pools."
  type = map(object({
    vm_size         = string
    min_count       = number
    max_count       = number
    os_disk_size_gb = number
    priority        = optional(string, "Regular")
    node_labels     = optional(map(string), {})
    node_taints     = optional(list(string), [])
  }))
}

variable "service_cidr" {
  description = "Kubernetes service CIDR."
  type        = string
}

variable "dns_service_ip" {
  description = "Kubernetes DNS service IP."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
