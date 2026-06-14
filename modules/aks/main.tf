resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name_prefix}-aks-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                              = "${var.name_prefix}-aks"
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.dns_prefix
  kubernetes_version                = var.kubernetes_version
  private_cluster_enabled           = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  local_account_disabled            = true
  tags                              = var.tags

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool.vm_size
    node_count                   = var.system_node_pool.node_count
    os_disk_size_gb              = var.system_node_pool.os_disk_size_gb
    vnet_subnet_id               = var.aks_subnet_id
    only_critical_addons_enabled = true
    type                         = "VirtualMachineScaleSets"
    zones                        = var.availability_zones
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    outbound_type     = var.outbound_type
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  os_disk_size_gb       = each.value.os_disk_size_gb
  vnet_subnet_id        = var.aks_subnet_id
  mode                  = "User"
  enable_auto_scaling   = true
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  priority              = each.value.priority
  eviction_policy       = each.value.priority == "Spot" ? "Delete" : null
  zones                 = var.availability_zones
  tags                  = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
