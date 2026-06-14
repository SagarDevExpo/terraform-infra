output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_endpoint" {
  description = "AKS cluster endpoint"
  value       = azurerm_kubernetes_cluster.this.kube_config.0.host
}

output "cluster_certificate" {
  description = "AKS cluster certificate"
  value       = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.this.id
}

output "kubelet_identity_object_id" {
  description = "AKS kubelet identity object ID"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}
