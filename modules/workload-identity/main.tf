resource "azurerm_user_assigned_identity" "this" {
  for_each = var.identities

  name                = "${var.name_prefix}-${each.key}-uai"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  for_each = var.identities

  name                = "${var.name_prefix}-${each.key}-fic"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.this[each.key].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"
}

resource "azurerm_role_assignment" "this" {
  for_each = {
    for item in flatten([
      for identity_name, identity in var.identities : [
        for role in identity.role_assignments : {
          key           = "${identity_name}-${replace(role.role_definition_name, " ", "-")}-${substr(sha1(role.scope), 0, 8)}"
          identity_name = identity_name
          role_name     = role.role_definition_name
          scope         = role.scope
        }
      ]
    ]) : item.key => item
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_name
  principal_id         = azurerm_user_assigned_identity.this[each.value.identity_name].principal_id
}
