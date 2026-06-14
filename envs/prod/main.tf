locals {
  tags = merge(var.tags, {
    Application = "ccoehub"
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = "platform-engineering"
  })
}

resource "azurerm_resource_group" "platform" {
  name     = "rg-${var.name_prefix}-platform"
  location = var.location
  tags     = local.tags
}

module "landing_zone" {
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
  source = "../../modules/vnet"

  name_prefix         = var.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.platform.name
  address_space       = var.spoke_address_space
  subnets             = var.subnets
  create_route_table  = true
  tags                = local.tags
}

module "acr" {
  source = "../../modules/acr"

  registry_name           = var.acr_name
  resource_group_name     = azurerm_resource_group.platform.name
  location                = var.location
  sku                     = "Premium"
  admin_enabled           = false
  zone_redundancy_enabled = true

  tags = local.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  vault_name                    = var.key_vault_name
  resource_group_name           = azurerm_resource_group.platform.name
  location                      = var.location
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  public_network_access_enabled = false

  tags = local.tags
}

module "aks" {
  source = "../../modules/aks"

  name_prefix            = var.name_prefix
  location               = var.location
  resource_group_name    = azurerm_resource_group.platform.name
  dns_prefix             = var.name_prefix
  kubernetes_version     = var.kubernetes_version
  aks_subnet_id          = module.vnet.subnet_ids["aks"]
  acr_id                 = module.acr.id
  key_vault_id           = module.keyvault.id
  admin_group_object_ids = var.aks_admin_group_object_ids
  system_node_pool       = var.system_node_pool
  user_node_pools        = var.user_node_pools
  service_cidr           = var.service_cidr
  dns_service_ip         = var.dns_service_ip
  log_retention_days     = 90
  tags                   = local.tags
}
