resource "azurerm_resource_group" "management" {
  name     = "rg-${var.name_prefix}-management"
  location = var.location
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "connectivity" {
  name     = "rg-${var.name_prefix}-connectivity"
  location = var.location
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_log_analytics_workspace" "platform" {
  name                = "${var.name_prefix}-platform-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_virtual_network" "hub" {
  name                = "${var.name_prefix}-hub-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.connectivity.name
  address_space       = var.hub_address_space
  tags                = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_prefix]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "shared_services" {
  name                 = "snet-shared-services"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.shared_services_subnet_prefix]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "bastion" {
  count = var.bastion_subnet_prefix == null ? 0 : 1

  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

resource "azurerm_private_dns_zone" "zones" {
  for_each = toset(var.private_dns_zones)

  name                = each.value
  resource_group_name = azurerm_resource_group.connectivity.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each = azurerm_private_dns_zone.zones

  name                  = "${var.name_prefix}-${replace(each.key, ".", "-")}-hub"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_public_ip" "waf" {
  name                = "${var.name_prefix}-waf-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.management.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_policy_definition" "require_tags" {
  name         = "${var.name_prefix}-require-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "CCOEHub required tags"
  description  = "Requires baseline tags on Azure resources."

  parameters = jsonencode({
    requiredTags = {
      type = "Array"
      metadata = {
        displayName = "Required tag names"
      }
    }
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        for tag_name in var.required_tags : {
          field  = "tags['${tag_name}']"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_policy_definition" "deny_public_aks" {
  name         = "${var.name_prefix}-deny-public-aks"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "CCOEHub deny public AKS"
  description  = "Denies AKS clusters that do not use a private API server."

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.ContainerService/managedClusters"
        },
        {
          field  = "Microsoft.ContainerService/managedClusters/apiServerAccessProfile.enablePrivateCluster"
          equals = "false"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "require_tags" {
  name                 = "${var.name_prefix}-require-tags"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  display_name         = "CCOEHub required tags"
  location             = var.location

  parameters = jsonencode({
    requiredTags = {
      value = var.required_tags
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_subscription_policy_assignment" "deny_public_aks" {
  name                 = "${var.name_prefix}-deny-public-aks"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.deny_public_aks.id
  display_name         = "CCOEHub deny public AKS"
  location             = var.location
}
