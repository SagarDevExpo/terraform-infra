name_prefix = "ch-np-a"

subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
tenant_id       = "00000000-0000-0000-0000-000000000000"

location = "eastus"

hub_address_space = ["10.30.0.0/16"]

firewall_subnet_prefix        = "10.30.0.0/26"
shared_services_subnet_prefix = "10.30.1.0/24"

private_dns_zones = [
  "privatelink.azurecr.io",
  "privatelink.vaultcore.azure.net",
  "privatelink.eastus.azmk8s.io"
]

spoke_address_space = ["10.40.0.0/16"]

subnets = {
  aks = {
    address_prefixes = ["10.40.10.0/23"]
    service_endpoints = [
      "Microsoft.ContainerRegistry",
      "Microsoft.KeyVault"
    ]
  }
  private_endpoints = {
    address_prefixes = ["10.40.20.0/24"]
  }
}

acr_name       = "chnpaacr001"
key_vault_name = "ch-np-a-kv-001"

kubernetes_version = "1.30.4"
service_cidr       = "10.41.0.0/16"
dns_service_ip     = "10.41.0.10"

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
  spot = {
    vm_size         = "Standard_D4s_v5"
    min_count       = 0
    max_count       = 5
    os_disk_size_gb = 128
    priority        = "Spot"
    node_labels = {
      workload = "ci"
      capacity = "spot"
    }
    node_taints = [
      "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
    ]
  }
}

tags = {
  CostCenter = "ccoehub"
  DataClass  = "internal"
  Account    = "account-a"
}
