resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-spoke-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

resource "azurerm_route_table" "this" {
  count = var.create_route_table ? 1 : 0

  name                = "${var.name_prefix}-rt"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = var.create_route_table ? azurerm_subnet.this : {}

  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.this[0].id
}
