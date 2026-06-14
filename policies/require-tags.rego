# Policy to require tags on all resources
package terraform_policies

import future.keywords

# Require Name tag on all resources
__rego_metadoc__ := {
  "title": "Require Name Tag",
  "description": "Ensures all resources have a Name tag",
  "related_resources": [],
  "services": ["all"],
  "categories": ["tagging"],
  "severity": "medium",
  "guidelines": "All resources should have a Name tag for better identification and management."
}

# Default deny
violation contains msg if {
  not has_name_tag(input.resource)
  msg := sprintf("Resource %s must have a Name tag", [input.resource.type])
}

has_name_tag(resource) if {
  resource.tags.Name
}

# Policy to deny public AKS clusters
package terraform_policies

import future.keywords

__rego_metadoc__ := {
  "title": "Deny Public AKS",
  "description": "Prevents AKS clusters from being exposed to the public internet",
  "related_resources": [],
  "services": ["aks"],
  "categories": ["security"],
  "severity": "high",
  "guidelines": "AKS clusters should not be exposed to the public internet unless explicitly required for specific scenarios."
}

# Deny AKS clusters with public access enabled
violation contains msg if {
  resource := input.resource
  resource.type == "azurerm_kubernetes_cluster"
  resource.values.kube_config.0.enable_public_ip == true
  msg := "AKS clusters must not have public IP access enabled"
}

# Deny AKS clusters with public network access
violation contains msg if {
  resource := input.resource
  resource.type == "azurerm_kubernetes_cluster"
  resource.values.kube_config.0.public_network_access_enabled == true
  msg := "AKS clusters must not have public network access enabled"
}