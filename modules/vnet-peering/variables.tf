variable "name_prefix" { type = string }
variable "hub_resource_group_name" { type = string }
variable "hub_vnet_name" { type = string }
variable "hub_vnet_id" { type = string }
variable "spoke_resource_group_name" { type = string }
variable "spoke_vnet_name" { type = string }
variable "spoke_vnet_id" { type = string }
variable "allow_gateway_transit" {
  type    = bool
  default = false
}
variable "use_remote_gateways" {
  type    = bool
  default = false
}
