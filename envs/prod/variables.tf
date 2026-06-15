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
    landing_zone      = bool
    vnet              = bool
    acr               = bool
    keyvault          = bool
    aks               = bool
    firewall          = optional(bool, false)
    bastion           = optional(bool, false)
    vnet_peering      = optional(bool, false)
    nat_gateway       = optional(bool, false)
    app_gateway_waf   = optional(bool, false)
    private_endpoints = optional(bool, false)
    defender          = optional(bool, false)
    budget            = optional(bool, false)
    diagnostics       = optional(bool, false)
    workload_identity = optional(bool, false)
    gitops_addons     = optional(bool, false)
    container_apps    = optional(bool, false)
    redis             = optional(bool, false)
    postgres          = optional(bool, false)
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

  validation {
    condition = (
      !(
        var.enabled_modules.firewall ||
        var.enabled_modules.bastion ||
        var.enabled_modules.defender ||
        var.enabled_modules.budget ||
        var.enabled_modules.diagnostics
      ) ||
      var.enabled_modules.landing_zone
    )
    error_message = "Foundation add-ons require landing_zone to be enabled."
  }

  validation {
    condition = (
      !(
        var.enabled_modules.vnet_peering ||
        var.enabled_modules.nat_gateway ||
        var.enabled_modules.app_gateway_waf ||
        var.enabled_modules.private_endpoints ||
        var.enabled_modules.container_apps ||
        var.enabled_modules.redis ||
        var.enabled_modules.postgres
      ) ||
      (
        var.enabled_modules.landing_zone &&
        var.enabled_modules.vnet
      )
    )
    error_message = "Platform add-ons require landing_zone and vnet to be enabled."
  }

  validation {
    condition = (
      !(
        var.enabled_modules.workload_identity ||
        var.enabled_modules.gitops_addons
      ) ||
      var.enabled_modules.aks
    )
    error_message = "AKS add-ons require aks to be enabled."
  }

}

variable "bastion_subnet_prefix" {
  description = "Optional AzureBastionSubnet CIDR."
  type        = string
  default     = null
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

variable "private_endpoints" {
  description = "Private endpoints keyed by logical name."
  type = map(object({
    resource_id          = string
    subresource_names    = list(string)
    private_dns_zone_ids = optional(list(string), [])
  }))
  default = {}
}

variable "budget" {
  description = "Subscription budget configuration."
  type = object({
    amount     = number
    start_date = string
    end_date   = optional(string)
    notifications = optional(map(object({
      threshold      = number
      contact_emails = list(string)
    })), {})
  })
  default = null
}

variable "diagnostic_targets" {
  description = "Extra diagnostic targets keyed by logical name."
  type = map(object({
    resource_id    = string
    log_categories = optional(list(string), [])
    enable_metrics = optional(bool, true)
  }))
  default = {}
}

variable "workload_identities" {
  description = "AKS workload identities keyed by app name."
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

variable "gitops_addons" {
  description = "Flux GitOps add-on configuration."
  type = object({
    git_repository_url       = string
    git_reference_type       = optional(string, "branch")
    git_reference_value      = optional(string, "main")
    kustomization_path       = optional(string, "./clusters/platform-addons")
    sync_interval_in_seconds = optional(number, 300)
  })
  default = null
}

variable "container_apps" {
  description = "Container apps keyed by app name."
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

variable "redis" {
  description = "Redis configuration."
  type = object({
    capacity                      = optional(number, 1)
    family                        = optional(string, "C")
    sku_name                      = optional(string, "Standard")
    redis_version                 = optional(string, "6")
    public_network_access_enabled = optional(bool, false)
  })
  default = {}
}

variable "postgres" {
  description = "PostgreSQL flexible server configuration."
  type = object({
    administrator_login           = optional(string, "psqladmin")
    administrator_password        = optional(string)
    postgres_version              = optional(string, "16")
    sku_name                      = optional(string, "GP_Standard_D2s_v3")
    storage_mb                    = optional(number, 32768)
    backup_retention_days         = optional(number, 7)
    geo_redundant_backup_enabled  = optional(bool, false)
    public_network_access_enabled = optional(bool, false)
    zone                          = optional(string, "1")
    databases                     = optional(list(string), ["app"])
  })
  default   = {}
  sensitive = true
}

variable "app_gateway_waf" {
  description = "Application Gateway WAF configuration."
  type = object({
    capacity                 = optional(number, 2)
    waf_mode                 = optional(string, "Prevention")
    ssl_certificate_data     = optional(string)
    ssl_certificate_password = optional(string)
  })
  default   = {}
  sensitive = true
}
