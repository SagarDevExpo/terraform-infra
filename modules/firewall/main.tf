resource "azurerm_public_ip" "firewall" {
  name                = "${var.name_prefix}-fw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_firewall_policy" "this" {
  name                = "${var.name_prefix}-fw-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku_tier
  tags                = var.tags
}

resource "azurerm_firewall" "this" {
  name                = "${var.name_prefix}-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this.id
  zones               = var.availability_zones
  tags                = var.tags

  ip_configuration {
    name                 = "default"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_route" "default_to_firewall" {
  count = var.route_table_id == null ? 0 : 1

  name                   = "default-to-azure-firewall"
  resource_group_name    = var.route_table_resource_group_name
  route_table_name       = var.route_table_name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
}
