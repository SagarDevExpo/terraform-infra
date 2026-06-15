variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "postgres_version" {
  type    = string
  default = "16"
}
variable "administrator_login" {
  type    = string
  default = "psqladmin"
}
variable "administrator_password" {
  type      = string
  sensitive = true
}
variable "sku_name" {
  type    = string
  default = "GP_Standard_D2s_v3"
}
variable "storage_mb" {
  type    = number
  default = 32768
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "zone" {
  type    = string
  default = "1"
}
variable "databases" {
  type    = list(string)
  default = ["app"]
}
variable "tags" {
  type    = map(string)
  default = {}
}
