variable "name_prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_ids" {
  description = "Subnet IDs to associate to NAT Gateway."
  type        = map(string)
}
variable "idle_timeout_in_minutes" {
  type    = number
  default = 4
}
variable "availability_zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}
variable "tags" {
  type    = map(string)
  default = {}
}
