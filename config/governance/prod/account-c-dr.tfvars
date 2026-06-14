subscription_id = "cccccccc-cccc-cccc-cccc-cccccccccccc"
tenant_id       = "00000000-0000-0000-0000-000000000000"

name_prefix      = "ch-prd-c"
primary_location = "eastus"

dr_pairings = {
  eastus  = "eastus2"
  eastus2 = "eastus"
}

tags = {
  CostCenter = "ccoehub"
  DataClass  = "confidential"
  Account    = "account-c"
  Scope      = "account-governance"
}
