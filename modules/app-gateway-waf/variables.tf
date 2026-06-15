variable "name_prefix" {
  description = "Name prefix for Application Gateway resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "subnet_id" {
  description = "Dedicated Application Gateway subnet ID."
  type        = string
}

variable "capacity" {
  description = "Application Gateway instance count."
  type        = number
  default     = 2
}

variable "waf_mode" {
  description = "WAF mode."
  type        = string
  default     = "Prevention"
}

variable "ssl_certificate_data" {
  description = "Base64-encoded PFX certificate data."
  type        = string
  sensitive   = true
}

variable "ssl_certificate_password" {
  description = "PFX certificate password."
  type        = string
  sensitive   = true
}

variable "availability_zones" {
  description = "Availability zones."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
