variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "capacity" {
  type    = number
  default = 1
}
variable "family" {
  type    = string
  default = "C"
}
variable "sku_name" {
  type    = string
  default = "Standard"
}
variable "redis_version" {
  type    = string
  default = "6"
}
variable "public_network_access_enabled" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
