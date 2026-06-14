resource "azurerm_container_registry" "acr" {
  name                          = var.registry_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  tags                          = var.tags

  dynamic "georeplications" {
    for_each = var.georeplication_locations

    content {
      location                = georeplications.value
      zone_redundancy_enabled = var.zone_redundancy_enabled
      tags                    = var.tags
    }
  }
}
