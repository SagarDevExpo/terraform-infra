locals {
  platform_enabled = (
    var.enabled_modules.vnet ||
    var.enabled_modules.acr ||
    var.enabled_modules.keyvault ||
    var.enabled_modules.aks ||
    var.enabled_modules.nat_gateway ||
    var.enabled_modules.app_gateway_waf ||
    var.enabled_modules.private_endpoints ||
    var.enabled_modules.workload_identity ||
    var.enabled_modules.gitops_addons ||
    var.enabled_modules.container_apps ||
    var.enabled_modules.redis ||
    var.enabled_modules.postgres
  )

  tags = merge(var.tags, {
    Application = "ccoehub"
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = "platform-engineering"
  })

  managed_private_endpoints = merge(
    var.private_endpoints,
    var.enabled_modules.acr ? {
      acr = {
        resource_id          = module.acr[0].id
        subresource_names    = ["registry"]
        private_dns_zone_ids = compact([try(module.landing_zone[0].private_dns_zone_ids["privatelink.azurecr.io"], null)])
      }
    } : {},
    var.enabled_modules.keyvault ? {
      keyvault = {
        resource_id          = module.keyvault[0].id
        subresource_names    = ["vault"]
        private_dns_zone_ids = compact([try(module.landing_zone[0].private_dns_zone_ids["privatelink.vaultcore.azure.net"], null)])
      }
    } : {},
    var.enabled_modules.redis ? {
      redis = {
        resource_id          = module.redis[0].id
        subresource_names    = ["redisCache"]
        private_dns_zone_ids = compact([try(module.landing_zone[0].private_dns_zone_ids["privatelink.redis.cache.windows.net"], null)])
      }
    } : {},
    var.enabled_modules.postgres ? {
      postgres = {
        resource_id          = module.postgres[0].id
        subresource_names    = ["postgresqlServer"]
        private_dns_zone_ids = compact([try(module.landing_zone[0].private_dns_zone_ids["privatelink.postgres.database.azure.com"], null)])
      }
    } : {}
  )

  diagnostic_targets = merge(
    var.diagnostic_targets,
    var.enabled_modules.acr ? {
      acr = {
        resource_id    = module.acr[0].id
        log_categories = ["ContainerRegistryRepositoryEvents", "ContainerRegistryLoginEvents"]
        enable_metrics = true
      }
    } : {},
    var.enabled_modules.keyvault ? {
      keyvault = {
        resource_id    = module.keyvault[0].id
        log_categories = ["AuditEvent"]
        enable_metrics = true
      }
    } : {},
    var.enabled_modules.aks ? {
      aks = {
        resource_id    = module.aks[0].id
        log_categories = ["kube-apiserver", "kube-audit", "kube-controller-manager", "kube-scheduler"]
        enable_metrics = true
      }
    } : {},
    var.enabled_modules.redis ? {
      redis = {
        resource_id    = module.redis[0].id
        log_categories = []
        enable_metrics = true
      }
    } : {}
  )
}

resource "azurerm_resource_group" "platform" {
  count = local.platform_enabled ? 1 : 0

  name     = "rg-${var.name_prefix}-platform"
  location = var.location
  tags     = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

module "landing_zone" {
  count = var.enabled_modules.landing_zone ? 1 : 0

  source = "../../modules/landing-zone"

  name_prefix                   = "${var.name_prefix}-lz"
  subscription_id               = var.subscription_id
  location                      = var.location
  hub_address_space             = var.hub_address_space
  firewall_subnet_prefix        = var.firewall_subnet_prefix
  shared_services_subnet_prefix = var.shared_services_subnet_prefix
  bastion_subnet_prefix         = var.bastion_subnet_prefix
  private_dns_zones             = var.private_dns_zones
  tags                          = local.tags
}

module "vnet" {
  count = var.enabled_modules.vnet ? 1 : 0

  source = "../../modules/vnet"

  name_prefix         = var.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.platform[0].name
  address_space       = var.spoke_address_space
  subnets             = var.subnets
  create_route_table  = true
  tags                = local.tags
}

module "acr" {
  count = var.enabled_modules.acr ? 1 : 0

  source = "../../modules/acr"

  registry_name                 = var.acr_name
  resource_group_name           = azurerm_resource_group.platform[0].name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  zone_redundancy_enabled       = true
  public_network_access_enabled = false # Premium SKU supports fully private; private endpoints required

  tags = local.tags
}

module "keyvault" {
  count = var.enabled_modules.keyvault ? 1 : 0

  source = "../../modules/keyvault"

  vault_name                    = var.key_vault_name
  resource_group_name           = azurerm_resource_group.platform[0].name
  location                      = var.location
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  public_network_access_enabled = false

  tags = local.tags
}

module "aks" {
  count = var.enabled_modules.aks ? 1 : 0

  source = "../../modules/aks"

  name_prefix            = var.name_prefix
  location               = var.location
  resource_group_name    = azurerm_resource_group.platform[0].name
  dns_prefix             = var.name_prefix
  kubernetes_version     = var.kubernetes_version
  aks_subnet_id          = try(module.vnet[0].subnet_ids["aks"], null)
  acr_id                 = try(module.acr[0].id, null)
  key_vault_id           = try(module.keyvault[0].id, null)
  admin_group_object_ids = var.aks_admin_group_object_ids
  system_node_pool       = var.system_node_pool
  user_node_pools        = var.user_node_pools
  service_cidr           = var.service_cidr
  dns_service_ip         = var.dns_service_ip
  log_retention_days     = 90
  # availability_zones uses module default ["1","2","3"] — prod uses zone-capable VM SKUs
  tags = local.tags
}

module "firewall" {
  count = var.enabled_modules.firewall ? 1 : 0

  source = "../../modules/firewall"

  name_prefix                     = var.name_prefix
  location                        = var.location
  resource_group_name             = module.landing_zone[0].connectivity_resource_group_name
  firewall_subnet_id              = module.landing_zone[0].firewall_subnet_id
  route_table_id                  = try(module.vnet[0].route_table_id, null)
  route_table_name                = try(module.vnet[0].route_table_name, null)
  route_table_resource_group_name = try(azurerm_resource_group.platform[0].name, null)
  tags                            = local.tags
}

module "bastion" {
  count = var.enabled_modules.bastion ? 1 : 0

  source = "../../modules/bastion"

  name_prefix         = var.name_prefix
  location            = var.location
  resource_group_name = module.landing_zone[0].connectivity_resource_group_name
  subnet_id           = module.landing_zone[0].bastion_subnet_id
  tags                = local.tags
}

module "vnet_peering" {
  count = var.enabled_modules.vnet_peering ? 1 : 0

  source = "../../modules/vnet-peering"

  name_prefix               = var.name_prefix
  hub_resource_group_name   = module.landing_zone[0].connectivity_resource_group_name
  hub_vnet_name             = module.landing_zone[0].hub_vnet_name
  hub_vnet_id               = module.landing_zone[0].hub_vnet_id
  spoke_resource_group_name = azurerm_resource_group.platform[0].name
  spoke_vnet_name           = module.vnet[0].vnet_name
  spoke_vnet_id             = module.vnet[0].vnet_id
}

module "nat_gateway" {
  count = var.enabled_modules.nat_gateway ? 1 : 0

  source = "../../modules/nat-gateway"

  name_prefix         = var.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.platform[0].name
  subnet_ids          = module.vnet[0].subnet_ids
  tags                = local.tags
}

module "app_gateway_waf" {
  count = var.enabled_modules.app_gateway_waf ? 1 : 0

  source = "../../modules/app-gateway-waf"

  name_prefix              = var.name_prefix
  location                 = var.location
  resource_group_name      = azurerm_resource_group.platform[0].name
  subnet_id                = module.vnet[0].subnet_ids["app_gateway"]
  capacity                 = var.app_gateway_waf.capacity
  waf_mode                 = var.app_gateway_waf.waf_mode
  ssl_certificate_data     = var.app_gateway_waf.ssl_certificate_data
  ssl_certificate_password = var.app_gateway_waf.ssl_certificate_password
  tags                     = local.tags
}

module "redis" {
  count = var.enabled_modules.redis ? 1 : 0

  source = "../../modules/redis"

  name_prefix                   = var.name_prefix
  location                      = var.location
  resource_group_name           = azurerm_resource_group.platform[0].name
  capacity                      = var.redis.capacity
  family                        = var.redis.family
  sku_name                      = var.redis.sku_name
  redis_version                 = var.redis.redis_version
  public_network_access_enabled = var.redis.public_network_access_enabled
  tags                          = local.tags
}

module "postgres" {
  count = var.enabled_modules.postgres ? 1 : 0

  source = "../../modules/postgres"

  name_prefix                   = var.name_prefix
  location                      = var.location
  resource_group_name           = azurerm_resource_group.platform[0].name
  administrator_login           = var.postgres.administrator_login
  administrator_password        = var.postgres.administrator_password
  postgres_version              = var.postgres.postgres_version
  sku_name                      = var.postgres.sku_name
  storage_mb                    = var.postgres.storage_mb
  backup_retention_days         = var.postgres.backup_retention_days
  geo_redundant_backup_enabled  = var.postgres.geo_redundant_backup_enabled
  public_network_access_enabled = var.postgres.public_network_access_enabled
  zone                          = var.postgres.zone
  databases                     = var.postgres.databases
  tags                          = local.tags
}

module "private_endpoints" {
  count = var.enabled_modules.private_endpoints ? 1 : 0

  source = "../../modules/private-endpoints"

  name_prefix         = var.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.platform[0].name
  subnet_id           = module.vnet[0].subnet_ids["private_endpoints"]
  private_endpoints   = local.managed_private_endpoints
  tags                = local.tags
}

module "defender" {
  count = var.enabled_modules.defender ? 1 : 0

  source = "../../modules/defender"
}

module "budget" {
  count = var.enabled_modules.budget ? 1 : 0

  source = "../../modules/budget"

  name_prefix     = var.name_prefix
  subscription_id = var.subscription_id
  amount          = var.budget.amount
  start_date      = var.budget.start_date
  end_date        = try(var.budget.end_date, null)
  notifications   = var.budget.notifications
}

module "diagnostic_settings" {
  count = var.enabled_modules.diagnostics ? 1 : 0

  source = "../../modules/diagnostic-settings"

  log_analytics_workspace_id = module.landing_zone[0].log_analytics_workspace_id
  targets                    = local.diagnostic_targets
}

module "workload_identity" {
  count = var.enabled_modules.workload_identity ? 1 : 0

  source = "../../modules/workload-identity"

  name_prefix         = var.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.platform[0].name
  oidc_issuer_url     = module.aks[0].oidc_issuer_url
  identities          = var.workload_identities
  tags                = local.tags
}

module "gitops_addons" {
  count = var.enabled_modules.gitops_addons ? 1 : 0

  source = "../../modules/gitops-addons"

  name_prefix              = var.name_prefix
  cluster_id               = module.aks[0].id
  git_repository_url       = var.gitops_addons.git_repository_url
  git_reference_type       = var.gitops_addons.git_reference_type
  git_reference_value      = var.gitops_addons.git_reference_value
  kustomization_path       = var.gitops_addons.kustomization_path
  sync_interval_in_seconds = var.gitops_addons.sync_interval_in_seconds
}

module "container_apps" {
  count = var.enabled_modules.container_apps ? 1 : 0

  source = "../../modules/container-apps"

  name_prefix                = var.name_prefix
  location                   = var.location
  resource_group_name        = azurerm_resource_group.platform[0].name
  log_analytics_workspace_id = module.landing_zone[0].log_analytics_workspace_id
  infrastructure_subnet_id   = try(module.vnet[0].subnet_ids["container_apps"], null)
  container_apps             = var.container_apps
  tags                       = local.tags
}
