variable "name_prefix" { type = string }
variable "subscription_id" { type = string }
variable "amount" {
  description = "Monthly budget amount."
  type        = number
}
variable "start_date" {
  description = "Budget start date in RFC3339 format."
  type        = string
}
variable "end_date" {
  description = "Budget end date in RFC3339 format."
  type        = string
  default     = null
}
variable "notifications" {
  description = "Budget notifications."
  type = map(object({
    threshold      = number
    contact_emails = list(string)
  }))
  default = {}
}
