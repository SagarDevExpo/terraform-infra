#!/usr/bin/env sh
set -eu

echo "Terraform Enterprise hybrid workspace setup"
echo
echo "Manage the workspaces from terraform-enterprise-config/tfe_workspace_config.hcl."
echo
echo "Expected workspace model:"
echo "  - terraform-infra-nonprod-account-a         -> envs/nonprod + config/nonprod/account-a.tfvars + auto-apply"
echo "  - terraform-infra-nonprod-account-b         -> envs/nonprod + config/nonprod/account-b.tfvars + auto-apply"
echo "  - terraform-infra-nonprod-account-c         -> envs/nonprod + config/nonprod/account-c.tfvars + auto-apply"
echo "  - terraform-infra-prod-account-c-eastus     -> envs/prod + config/prod/account-c-eastus.tfvars + manual approval"
echo "  - terraform-infra-prod-account-c-eastus2    -> envs/prod + config/prod/account-c-eastus2.tfvars + manual approval"
echo "  - terraform-infra-prod-account-d-centralus  -> envs/prod + config/prod/account-d-centralus.tfvars + manual approval"
echo "  - terraform-infra-prod-account-d-westus2    -> envs/prod + config/prod/account-d-westus2.tfvars + manual approval"
echo "  - terraform-infra-prod-account-c-governance -> envs/governance + config/governance/prod/account-c-dr.tfvars + manual approval"
echo "  - terraform-infra-prod-account-d-governance -> envs/governance + config/governance/prod/account-d-dr.tfvars + manual approval"
echo
echo "After applying the governance config, store these workspace IDs in GitLab CI variables:"
echo "  - TFE_WORKSPACE_ID_NONPROD_ACCOUNT_A"
echo "  - TFE_WORKSPACE_ID_NONPROD_ACCOUNT_B"
echo "  - TFE_WORKSPACE_ID_NONPROD_ACCOUNT_C"
echo "  - TFE_WORKSPACE_ID_PROD_ACCOUNT_C_EASTUS"
echo "  - TFE_WORKSPACE_ID_PROD_ACCOUNT_C_EASTUS2"
echo "  - TFE_WORKSPACE_ID_PROD_ACCOUNT_D_CENTRALUS"
echo "  - TFE_WORKSPACE_ID_PROD_ACCOUNT_D_WESTUS2"
echo "  - TFE_WORKSPACE_ID_PROD_ACCOUNT_C_GOVERNANCE"
echo "  - TFE_WORKSPACE_ID_PROD_ACCOUNT_D_GOVERNANCE"
echo
echo "GitLab should also have:"
echo "  - TFE_HOSTNAME"
echo "  - TFE_TOKEN"
