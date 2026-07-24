# =============================================================================
# Personal / learning account tfvars — "account-personal"
# Subscription : Azure subscription 1 (free trial)
# Purpose      : Step-by-step personal implementation, one module at a time.
#
# PHASE 1 — Landing zone only.
# Everything else stays false until the previous phase is verified in Azure.
# =============================================================================

name_prefix = "sagar-personal"

subscription_id = "1c13ac76-badb-4d20-bf64-bcbb6b68ba95"
tenant_id       = "da4fda7e-4558-48ab-a7a9-5b06200c34c0"

location = "eastus"

# ------------------------------------------------------------
# PHASE TOGGLES — flip one group at a time, never all at once.
# ------------------------------------------------------------
enabled_modules = {
  # Phase 1 (current) — foundation
  landing_zone = true

  # Phase 2 — spoke network (enable after landing zone is verified)
  vnet = true

  # Phase 3 — registry + secrets (enable after vnet is verified)
  acr      = false
  keyvault = false

  # Phase 4 — Kubernetes (enable after acr + keyvault are verified)
  aks = false

  # Phase 5 — add-ons (enable one at a time, after aks is verified)
  firewall          = false
  bastion           = false
  vnet_peering      = false
  nat_gateway       = false
  app_gateway_waf   = false
  private_endpoints = false
  defender          = false
  budget            = false
  diagnostics       = false
  workload_identity = false
  gitops_addons     = false
  container_apps    = false
  redis             = false
  postgres          = false
}

# ------------------------------------------------------------
# Landing zone networking (Phase 1 values)
# These CIDRs are RFC 1918 private ranges — safe to use.
# hub = the central network; firewall/bastion subnets must fit inside it.
# ------------------------------------------------------------
hub_address_space             = ["10.0.0.0/16"]
firewall_subnet_prefix        = "10.0.0.0/26" # /26 is the minimum required by Azure Firewall
shared_services_subnet_prefix = "10.0.1.0/24"
bastion_subnet_prefix         = "10.0.2.0/26" # /26 is the minimum required by Azure Bastion

private_dns_zones = [
  "privatelink.azurecr.io",
  "privatelink.vaultcore.azure.net",
  "privatelink.redis.cache.windows.net",
  "privatelink.postgres.database.azure.com",
  "privatelink.eastus.azmk8s.io"
]

# ------------------------------------------------------------
# Phase 2 values — spoke network (fill in when you reach Phase 2)
# ------------------------------------------------------------
spoke_address_space = ["10.1.0.0/16"]

subnets = {
  aks = {
    address_prefixes  = ["10.1.0.0/22"]
    service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
  }
  private_endpoints = {
    address_prefixes = ["10.1.4.0/24"]
  }
  app_gateway = {
    address_prefixes = ["10.1.5.0/24"]
  }
  container_apps = {
    address_prefixes = ["10.1.6.0/23"]
  }
}

# ------------------------------------------------------------
# Phase 3 values — registry + key vault names must be globally unique
# ------------------------------------------------------------
acr_name       = "sagarpersonalacr001"   # globally unique across all of Azure
key_vault_name = "sagar-personal-kv-001" # globally unique across all of Azure

# ------------------------------------------------------------
# Phase 4 values — Kubernetes
# service_cidr must NOT overlap hub (10.0.x) or spoke (10.1.x)
# ------------------------------------------------------------
kubernetes_version = "1.30.4"
service_cidr       = "10.2.0.0/16"
dns_service_ip     = "10.2.0.10"

aks_admin_group_object_ids = [] # fill in your Entra ID group object ID in Phase 4

system_node_pool = {
  vm_size         = "Standard_B2s" # cheapest option for learning; 2 vCPU, 4GB RAM
  node_count      = 1              # single node to stay within free trial limits
  os_disk_size_gb = 30
}

user_node_pools = {} # add workload pools when needed in Phase 4

tags = {
  Owner       = "sagar"
  Environment = "personal"
  Purpose     = "learning"
  CostCenter  = "personal-dev"
  DataClass   = "non-production"
}
