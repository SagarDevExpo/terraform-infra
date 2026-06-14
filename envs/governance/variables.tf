variable "subscription_id" {
  description = "Azure subscription ID for account-level governance."
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "name_prefix" {
  description = "Governance resource name prefix."
  type        = string
}

variable "primary_location" {
  description = "Primary Azure region for account-level governance resources."
  type        = string
}

variable "dr_pairings" {
  description = "Primary-to-secondary region pairing map used by DR orchestration."
  type        = map(string)
}

variable "tags" {
  description = "Common governance tags."
  type        = map(string)
  default     = {}
}
