variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "sku" {
  type    = string
  default = "Standard"
}
variable "availability_zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}
variable "tags" {
  type    = map(string)
  default = {}
}
