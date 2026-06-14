locals {
  platform_enabled = (
    var.enabled_modules.vnet ||
    var.enabled_modules.acr ||
    var.enabled_modules.keyvault ||
    var.enabled_modules.aks
  )

  tags = merge(var.tags, {
    Application = "ccoehub"
    Environment = "nonprod"
    ManagedBy   = "terraform"
    Owner       = "platform-engineering"
  })
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

  registry_name           = var.acr_name
  resource_group_name     = azurerm_resource_group.platform[0].name
  location                = var.location
  sku                     = "Standard"
  admin_enabled           = false
  zone_redundancy_enabled = false

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
  tags                   = local.tags
}
