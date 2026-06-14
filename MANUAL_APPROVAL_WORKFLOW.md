# Terraform Enterprise Apply Workflow

## Key Point

GitLab does not run `terraform apply` in this repository. GitLab performs pre-flight checks and triggers Terraform Enterprise workspaces. Terraform Enterprise owns plan, apply, state, approval, and audit trail.

## Non-Prod Deployment

```text
GitLab MR
  → merge to main
  → GitLab validate_nonprod
  → GitLab compliance_nonprod
  → GitLab trigger_tfe_nonprod
  → TFE matching non-prod account workspace plans
  → TFE auto-applies
  → Azure non-prod is updated
```

Non-prod uses one workspace per Azure account. The account-level configs live in `config/nonprod/`, and those workspaces have auto-apply enabled.

## Production Deployment

```text
GitLab MR
  → merge to main
  → GitLab validate_prod
  → GitLab compliance_prod
  → GitLab trigger_tfe_prod
  → TFE regional prod workspace plans
  → TFE waits for manual approval
  → approver confirms apply in TFE
  → TFE applies
  → Azure prod is updated
```

Production uses one workspace per Azure account-region. Each regional workspace has isolated state and auto-apply disabled. DR/account-level orchestration is handled by a separate governance workspace, not by regional platform workspaces.

## GitLab Responsibilities

- Validate Terraform formatting and syntax.
- Run repository compliance checks.
- Trigger the correct Terraform Enterprise workspace.
- Never execute `terraform apply`.

## Terraform Enterprise Responsibilities

- Pull the GitLab repository through VCS integration.
- Run Terraform from the configured workspace working directory.
- Generate the execution plan.
- Apply non-prod automatically.
- Hold production runs for manual approval.
- Store state, run logs, approver identity, timestamps, policy results, and state versions.

## Workspace Mapping

| Workspace | Working Directory | Config File | Auto Apply | Triggered By |
|---|---|---|---:|---|
| `terraform-infra-nonprod-account-a` | `envs/nonprod` | `config/nonprod/account-a.tfvars` | Yes | `envs/nonprod/**`, `config/nonprod/account-a.tfvars`, `modules/**`, `policies/**`, `scripts/**` |
| `terraform-infra-nonprod-account-b` | `envs/nonprod` | `config/nonprod/account-b.tfvars` | Yes | `envs/nonprod/**`, `config/nonprod/account-b.tfvars`, `modules/**`, `policies/**`, `scripts/**` |
| `terraform-infra-nonprod-account-c` | `envs/nonprod` | `config/nonprod/account-c.tfvars` | Yes | `envs/nonprod/**`, `config/nonprod/account-c.tfvars`, `modules/**`, `policies/**`, `scripts/**` |
| `terraform-infra-prod-account-c-eastus` | `envs/prod` | `config/prod/account-c-eastus.tfvars` | No | `envs/prod/**`, `config/prod/account-c-eastus.tfvars`, `modules/**`, `policies/**`, `scripts/**` |
| `terraform-infra-prod-account-c-eastus2` | `envs/prod` | `config/prod/account-c-eastus2.tfvars` | No | `envs/prod/**`, `config/prod/account-c-eastus2.tfvars`, `modules/**`, `policies/**`, `scripts/**` |
| `terraform-infra-prod-account-d-centralus` | `envs/prod` | `config/prod/account-d-centralus.tfvars` | No | `envs/prod/**`, `config/prod/account-d-centralus.tfvars`, `modules/**`, `policies/**`, `scripts/**` |
| `terraform-infra-prod-account-d-westus2` | `envs/prod` | `config/prod/account-d-westus2.tfvars` | No | `envs/prod/**`, `config/prod/account-d-westus2.tfvars`, `modules/**`, `policies/**`, `scripts/**` |
| `terraform-infra-prod-account-c-governance` | `envs/governance` | `config/governance/prod/account-c-dr.tfvars` | No | `envs/governance/**`, `config/governance/prod/account-c-dr.tfvars`, `terraform-enterprise-config/**` |
| `terraform-infra-prod-account-d-governance` | `envs/governance` | `config/governance/prod/account-d-dr.tfvars` | No | `envs/governance/**`, `config/governance/prod/account-d-dr.tfvars`, `terraform-enterprise-config/**` |

## Required GitLab Variables

- `TFE_HOSTNAME`: Terraform Enterprise hostname, for example `app.terraform.io` or `tfe.company.com`.
- `TFE_TOKEN`: Terraform Enterprise API token with permission to create runs.
- `TFE_WORKSPACE_ID_NONPROD_ACCOUNT_A`: Terraform Enterprise workspace ID for non-prod account A.
- `TFE_WORKSPACE_ID_NONPROD_ACCOUNT_B`: Terraform Enterprise workspace ID for non-prod account B.
- `TFE_WORKSPACE_ID_NONPROD_ACCOUNT_C`: Terraform Enterprise workspace ID for non-prod account C.
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_C_EASTUS`: Terraform Enterprise workspace ID for prod account C East US.
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_C_EASTUS2`: Terraform Enterprise workspace ID for prod account C East US 2.
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_D_CENTRALUS`: Terraform Enterprise workspace ID for prod account D Central US.
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_D_WESTUS2`: Terraform Enterprise workspace ID for prod account D West US 2.
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_C_GOVERNANCE`: Terraform Enterprise workspace ID for prod account C governance.
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_D_GOVERNANCE`: Terraform Enterprise workspace ID for prod account D governance.

## Approval Anatomy

```text
TFE prod run queued
  → init
  → plan
  → policy checks
  → cost/security review if configured
  → status: planned_and_finished
  → waiting for confirmation
  → approved by platform/security approver
  → apply
  → state version created
```

## Interview Summary

We keep apply inside Terraform Enterprise. GitLab validates the repo, runs compliance checks, and triggers the matching TFE workspace. Non-prod is account-level and auto-applies from TFE after a successful plan. Prod is account-region-level, so each region has isolated state and waits for human approval. DR region pairings live in an account-level governance workspace. That balances fewer non-prod workspaces with stronger production blast-radius isolation.

## Multiple Accounts

For multiple Azure accounts/subscriptions, repeat the same pattern:

```text
non-prod:
  terraform-infra-nonprod-account-a
  terraform-infra-nonprod-account-b
  terraform-infra-nonprod-account-c

prod:
  terraform-infra-prod-account-c-eastus
  terraform-infra-prod-account-c-eastus2
  terraform-infra-prod-account-d-centralus
  terraform-infra-prod-account-d-westus2

governance:
  terraform-infra-prod-account-c-governance
  terraform-infra-prod-account-d-governance
```

Each workspace gets its own config file under `config/`, and GitLab passes the correct workspace ID through protected CI variables.

## Phased Onboarding Guardrails

Each account config uses `enabled_modules` to control rollout:

```hcl
enabled_modules = {
  landing_zone = true
  vnet         = false
  acr          = false
  keyvault     = false
  aks          = false
}
```

This lets new accounts start with landing zone only. Existing accounts keep all modules enabled. Terraform validation blocks invalid dependencies, for example `aks=true` without `vnet`, `acr`, and `keyvault`. Critical resources also use `prevent_destroy`, so accidentally turning a module flag off is blocked from deleting infrastructure.
