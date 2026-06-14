terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.55"
    }
  }
}

provider "tfe" {
  hostname = var.tfe_hostname
  token    = var.tfe_token
}

variable "tfe_hostname" {
  description = "Terraform Enterprise hostname."
  type        = string
}

variable "tfe_token" {
  description = "Terraform Enterprise API token."
  type        = string
  sensitive   = true
}

variable "organization" {
  description = "Terraform Enterprise organization."
  type        = string
}

variable "gitlab_project_identifier" {
  description = "GitLab project identifier, for example platform/terraform-infra."
  type        = string
}

variable "gitlab_oauth_token_id" {
  description = "Terraform Enterprise VCS OAuth token ID for GitLab."
  type        = string
}

locals {
  repo_branch = "main"

  workspaces = {
    nonprod_account_a = {
      name              = "terraform-infra-nonprod-account-a"
      working_directory = "envs/nonprod"
      auto_apply        = true
      trigger_prefixes  = ["envs/nonprod", "config/nonprod/account-a.tfvars", "modules", "policies", "scripts"]
      tf_cli_args_plan  = "-var-file=../../config/nonprod/account-a.tfvars"
    }
    nonprod_account_b = {
      name              = "terraform-infra-nonprod-account-b"
      working_directory = "envs/nonprod"
      auto_apply        = true
      trigger_prefixes  = ["envs/nonprod", "config/nonprod/account-b.tfvars", "modules", "policies", "scripts"]
      tf_cli_args_plan  = "-var-file=../../config/nonprod/account-b.tfvars"
    }
    prod_account_c_eastus = {
      name              = "terraform-infra-prod-account-c-eastus"
      working_directory = "envs/prod"
      auto_apply        = false
      trigger_prefixes  = ["envs/prod", "config/prod/account-c-eastus.tfvars", "modules", "policies", "scripts"]
      tf_cli_args_plan  = "-var-file=../../config/prod/account-c-eastus.tfvars"
    }
    prod_account_c_eastus2 = {
      name              = "terraform-infra-prod-account-c-eastus2"
      working_directory = "envs/prod"
      auto_apply        = false
      trigger_prefixes  = ["envs/prod", "config/prod/account-c-eastus2.tfvars", "modules", "policies", "scripts"]
      tf_cli_args_plan  = "-var-file=../../config/prod/account-c-eastus2.tfvars"
    }
    prod_account_d_centralus = {
      name              = "terraform-infra-prod-account-d-centralus"
      working_directory = "envs/prod"
      auto_apply        = false
      trigger_prefixes  = ["envs/prod", "config/prod/account-d-centralus.tfvars", "modules", "policies", "scripts"]
      tf_cli_args_plan  = "-var-file=../../config/prod/account-d-centralus.tfvars"
    }
    prod_account_d_westus2 = {
      name              = "terraform-infra-prod-account-d-westus2"
      working_directory = "envs/prod"
      auto_apply        = false
      trigger_prefixes  = ["envs/prod", "config/prod/account-d-westus2.tfvars", "modules", "policies", "scripts"]
      tf_cli_args_plan  = "-var-file=../../config/prod/account-d-westus2.tfvars"
    }
    prod_account_c_governance = {
      name              = "terraform-infra-prod-account-c-governance"
      working_directory = "envs/governance"
      auto_apply        = false
      trigger_prefixes  = ["envs/governance", "config/governance/prod/account-c-dr.tfvars"]
      tf_cli_args_plan  = "-var-file=../../config/governance/prod/account-c-dr.tfvars"
    }
    prod_account_d_governance = {
      name              = "terraform-infra-prod-account-d-governance"
      working_directory = "envs/governance"
      auto_apply        = false
      trigger_prefixes  = ["envs/governance", "config/governance/prod/account-d-dr.tfvars"]
      tf_cli_args_plan  = "-var-file=../../config/governance/prod/account-d-dr.tfvars"
    }
  }
}

resource "tfe_workspace" "platform" {
  for_each = local.workspaces

  name              = each.value.name
  organization      = var.organization
  working_directory = each.value.working_directory
  auto_apply        = each.value.auto_apply
  queue_all_runs    = true
  trigger_prefixes  = each.value.trigger_prefixes

  vcs_repo {
    identifier     = var.gitlab_project_identifier
    branch         = local.repo_branch
    oauth_token_id = var.gitlab_oauth_token_id
  }
}

resource "tfe_variable" "tf_cli_args_plan" {
  for_each = local.workspaces

  key          = "TF_CLI_ARGS_plan"
  value        = each.value.tf_cli_args_plan
  category     = "env"
  workspace_id = tfe_workspace.platform[each.key].id
  description  = "Selects the account/region config file for this workspace."
}

output "workspace_ids" {
  description = "Workspace IDs to store as GitLab CI variables."
  value       = { for key, workspace in tfe_workspace.platform : key => workspace.id }
}
