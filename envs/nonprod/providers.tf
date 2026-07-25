terraform {
  # Terraform Cloud backend — stores state remotely and runs plan/apply.
  # Each account has its own workspace; this one maps to account-personal.
  cloud {
    organization = "cloudcentersdlc"
    workspaces {
      name = "terraform-infra-nonprod-account-personal"
    }
  }

  required_version = ">= 1.5.0, < 2.0.0" # pin to 1.x

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110" # 3.110+ but not 4.0
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
