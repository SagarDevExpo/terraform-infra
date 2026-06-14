name_prefix = "ch-np-c"

enabled_modules = {
  landing_zone = true
  vnet         = false
  acr          = false
  keyvault     = false
  aks          = false
}

subscription_id = "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"
tenant_id       = "00000000-0000-0000-0000-000000000000"

location = "eastus2"

hub_address_space = ["10.230.0.0/16"]

firewall_subnet_prefix        = "10.230.0.0/26"
shared_services_subnet_prefix = "10.230.1.0/24"

private_dns_zones = [
  "privatelink.azurecr.io",
  "privatelink.vaultcore.azure.net",
  "privatelink.eastus2.azmk8s.io"
]

spoke_address_space = ["10.240.0.0/16"]

subnets = {
  aks = {
    address_prefixes = ["10.240.10.0/23"]
    service_endpoints = [
      "Microsoft.ContainerRegistry",
      "Microsoft.KeyVault"
    ]
  }
  private_endpoints = {
    address_prefixes = ["10.240.20.0/24"]
  }
}

acr_name       = "chnpcacr001"
key_vault_name = "ch-np-c-kv-001"

kubernetes_version = "1.30.4"
service_cidr       = "10.241.0.0/16"
dns_service_ip     = "10.241.0.10"

aks_admin_group_object_ids = [
  "11111111-1111-1111-1111-111111111111"
]

system_node_pool = {
  vm_size         = "Standard_D4s_v5"
  node_count      = 3
  os_disk_size_gb = 128
}

user_node_pools = {
  apps = {
    vm_size         = "Standard_D4s_v5"
    min_count       = 2
    max_count       = 8
    os_disk_size_gb = 128
    node_labels = {
      workload = "apps"
    }
  }
}

tags = {
  CostCenter = "ccoehub"
  DataClass  = "internal"
  Account    = "account-c"
}
