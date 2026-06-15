resource "azurerm_kubernetes_cluster_extension" "flux" {
  name           = "flux"
  cluster_id     = var.cluster_id
  extension_type = "microsoft.flux"
}

resource "azurerm_kubernetes_flux_configuration" "addons" {
  name       = "${var.name_prefix}-addons"
  cluster_id = var.cluster_id
  namespace  = var.namespace
  scope      = "cluster"

  git_repository {
    url                      = var.git_repository_url
    reference_type           = var.git_reference_type
    reference_value          = var.git_reference_value
    sync_interval_in_seconds = var.sync_interval_in_seconds
  }

  kustomizations {
    name                       = "addons"
    path                       = var.kustomization_path
    sync_interval_in_seconds   = var.sync_interval_in_seconds
    retry_interval_in_seconds  = 60
    garbage_collection_enabled = true
  }

  depends_on = [azurerm_kubernetes_cluster_extension.flux]
}
