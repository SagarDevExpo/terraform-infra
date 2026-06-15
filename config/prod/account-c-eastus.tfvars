name_prefix = "ch-prd-c-eus"

enabled_modules = {
  landing_zone      = true
  vnet              = true
  acr               = true
  keyvault          = true
  aks               = true
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

subscription_id = "cccccccc-cccc-cccc-cccc-cccccccccccc"
tenant_id       = "00000000-0000-0000-0000-000000000000"

location = "eastus"

hub_address_space = ["10.50.0.0/16"]

firewall_subnet_prefix        = "10.50.0.0/26"
shared_services_subnet_prefix = "10.50.1.0/24"
bastion_subnet_prefix         = "10.50.2.0/26"

private_dns_zones = [
  "privatelink.azurecr.io",
  "privatelink.vaultcore.azure.net",
  "privatelink.redis.cache.windows.net",
  "privatelink.postgres.database.azure.com",
  "privatelink.eastus.azmk8s.io"
]

spoke_address_space = ["10.60.0.0/16"]

subnets = {
  aks = {
    address_prefixes = ["10.60.10.0/23"]
    service_endpoints = [
      "Microsoft.ContainerRegistry",
      "Microsoft.KeyVault"
    ]
  }
  private_endpoints = {
    address_prefixes = ["10.60.20.0/24"]
  }
  app_gateway = {
    address_prefixes = ["10.60.30.0/24"]
  }
  container_apps = {
    address_prefixes = ["10.60.40.0/23"]
  }
}

acr_name       = "chprdceusacr001"
key_vault_name = "ch-prd-c-eus-kv-001"

kubernetes_version = "1.30.4"
service_cidr       = "10.61.0.0/16"
dns_service_ip     = "10.61.0.10"

aks_admin_group_object_ids = [
  "22222222-2222-2222-2222-222222222222"
]

system_node_pool = {
  vm_size         = "Standard_D4s_v5"
  node_count      = 3
  os_disk_size_gb = 128
}

user_node_pools = {
  apps = {
    vm_size         = "Standard_D8s_v5"
    min_count       = 3
    max_count       = 12
    os_disk_size_gb = 128
    node_labels = {
      workload = "apps"
    }
  }
}

tags = {
  CostCenter = "ccoehub"
  DataClass  = "confidential"
  Account    = "account-c"
}
