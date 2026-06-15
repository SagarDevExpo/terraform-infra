variable "name_prefix" { type = string }
variable "cluster_id" { type = string }
variable "namespace" {
  type    = string
  default = "flux-system"
}
variable "git_repository_url" { type = string }
variable "git_reference_type" {
  type    = string
  default = "branch"
}
variable "git_reference_value" {
  type    = string
  default = "main"
}
variable "kustomization_path" {
  type    = string
  default = "./clusters/platform-addons"
}
variable "sync_interval_in_seconds" {
  type    = number
  default = 300
}
