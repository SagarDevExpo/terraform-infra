subscription_id = "dddddddd-dddd-dddd-dddd-dddddddddddd"
tenant_id       = "00000000-0000-0000-0000-000000000000"

name_prefix      = "ch-prd-d"
primary_location = "centralus"

dr_pairings = {
  centralus = "westus2"
  westus2   = "centralus"
}

tags = {
  CostCenter = "ccoehub"
  DataClass  = "confidential"
  Account    = "account-d"
  Scope      = "account-governance"
}
