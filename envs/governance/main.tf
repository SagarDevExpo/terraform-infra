locals {
  tags = merge(var.tags, {
    Application = "ccoehub"
    Environment = "prod"
    ManagedBy   = "terraform"
    Owner       = "platform-engineering"
    Scope       = "account-governance"
  })
}

resource "azurerm_resource_group" "governance" {
  name     = "rg-${var.name_prefix}-governance"
  location = var.primary_location
  tags     = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "dr_pairing" {
  for_each = var.dr_pairings

  name     = "rg-${var.name_prefix}-${each.key}-to-${each.value}-dr"
  location = each.value
  tags = merge(local.tags, {
    PrimaryRegion   = each.key
    SecondaryRegion = each.value
  })

  lifecycle {
    prevent_destroy = true
  }
}
