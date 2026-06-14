data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                            = var.vault_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.sku_name
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  enable_rbac_authorization       = var.enable_rbac_authorization
  public_network_access_enabled   = var.public_network_access_enabled
  tags                            = var.tags

  network_acls {
    default_action = var.network_acls_default_action
    bypass         = var.bypass
  }

  lifecycle {
    prevent_destroy = true
  }
}
