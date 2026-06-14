# Terraform Infra Architecture

This repository is built around one rule: GitLab validates and triggers, but Terraform Enterprise owns plan, apply, state, approval, and audit history.

## High-Level Flow

```mermaid
flowchart TD
  Dev[Developer changes Terraform code] --> MR[GitLab merge request]
  MR --> Main[Merge to main]
  Main --> Validate[GitLab validate stage<br/>terraform fmt + terraform validate]
  Validate --> Compliance[GitLab compliance stage<br/>policy + repo guardrail checks]
  Compliance --> Router[GitLab trigger_tfe stage<br/>rules decide target workspace]

  Router --> NP[TFE non-prod account workspace<br/>auto-apply enabled]
  Router --> PR[TFE prod account-region workspace<br/>manual approval required]
  Router --> GOV[TFE governance workspace<br/>DR/account-level orchestration]

  NP --> NPPlan[TFE plan]
  NPPlan --> NPApply[TFE auto-apply]

  PR --> PRPlan[TFE plan]
  PRPlan --> Approval[Manual approval in TFE]
  Approval --> PRApply[TFE apply]

  GOV --> GOVPlan[TFE plan]
  GOVPlan --> GOVApproval[Manual approval if configured]
  GOVApproval --> GOVApply[TFE apply]
```

## Repository Anatomy

```mermaid
flowchart LR
  Root[terraform-infra repo root<br/>docs, CI, scripts, policies] --> Envs[envs]
  Root --> Config[config]
  Root --> Modules[modules]
  Root --> Policies[policies]
  Root --> Scripts[scripts]
  Root --> TFEConfig[terraform-enterprise-config]

  Envs --> Nonprod[envs/nonprod<br/>non-prod root module]
  Envs --> Prod[envs/prod<br/>prod regional root module]
  Envs --> Governance[envs/governance<br/>account-level governance/DR]

  Config --> NPConfig[config/nonprod/*.tfvars<br/>one file per non-prod account]
  Config --> ProdConfig[config/prod/*.tfvars<br/>one file per prod account-region]
  Config --> GovConfig[config/governance/prod/*.tfvars<br/>DR pairings]

  Modules --> LZ[landing-zone]
  Modules --> VNet[vnet]
  Modules --> ACR[acr]
  Modules --> KV[keyvault]
  Modules --> AKS[aks]

  Nonprod --> Modules
  Prod --> Modules
  Governance --> GovConfig
```

## Workspace Model

| Scope | Workspace Pattern | Config Pattern | Apply Behavior |
|---|---|---|---|
| Non-prod | One workspace per account | `config/nonprod/account-a.tfvars` | Auto-apply after GitLab pre-flight |
| Prod platform | One workspace per account-region | `config/prod/account-c-eastus.tfvars` | TFE manual approval |
| Prod governance/DR | One workspace per prod account | `config/governance/prod/account-c-dr.tfvars` | TFE approval as configured |

Current workspaces:

```text
terraform-infra-nonprod-account-a       -> envs/nonprod + config/nonprod/account-a.tfvars
terraform-infra-nonprod-account-b       -> envs/nonprod + config/nonprod/account-b.tfvars
terraform-infra-nonprod-account-c       -> envs/nonprod + config/nonprod/account-c.tfvars
terraform-infra-prod-account-c-eastus   -> envs/prod    + config/prod/account-c-eastus.tfvars
terraform-infra-prod-account-c-eastus2  -> envs/prod    + config/prod/account-c-eastus2.tfvars
terraform-infra-prod-account-d-centralus -> envs/prod   + config/prod/account-d-centralus.tfvars
terraform-infra-prod-account-d-westus2  -> envs/prod    + config/prod/account-d-westus2.tfvars
terraform-infra-prod-account-c-governance -> envs/governance + config/governance/prod/account-c-dr.tfvars
terraform-infra-prod-account-d-governance -> envs/governance + config/governance/prod/account-d-dr.tfvars
```

## Module Enablement Guardrail

Each account config has an `enabled_modules` block:

```hcl
enabled_modules = {
  landing_zone = true
  vnet         = false
  acr          = false
  keyvault     = false
  aks          = false
}
```

This supports safe phased onboarding:

```mermaid
flowchart TD
  Start[New Azure account] --> LZOnly[Enable landing_zone only]
  LZOnly --> Validate[GitLab + Terraform validation]
  Validate --> TFE[TFE applies landing zone]
  TFE --> PlatformReady{Ready for platform modules?}
  PlatformReady -- No --> Stop[Keep account foundation-only]
  PlatformReady -- Yes --> EnablePlatform[Enable vnet, acr, keyvault]
  EnablePlatform --> EnableAKS[Enable aks after dependencies exist]
```

Guardrails:

- `aks = true` requires `landing_zone`, `vnet`, `acr`, and `keyvault`.
- `vnet`, `acr`, and `keyvault` require `landing_zone`.
- Critical resources use `prevent_destroy` so disabling an already-created module does not casually destroy infrastructure.
- GitLab compliance checks verify the `enabled_modules` block before triggering TFE.

## Account and Region Targeting

The Azure subscription is selected through `subscription_id` in the chosen tfvars file. The Azure region is selected through `location`.

```mermaid
flowchart LR
  Workspace[TFE workspace] --> WorkingDir[Working directory<br/>envs/nonprod or envs/prod]
  Workspace --> PlanArgs[Plan args<br/>-var-file=../../config/...tfvars]
  PlanArgs --> Vars[subscription_id + tenant_id + location]
  Vars --> Azure[Target Azure subscription and region]
```

For non-prod, one account workspace can target the account's selected primary region. For production, regional blast-radius isolation is stronger, so each prod account-region gets its own workspace and state.

## Local Command Pattern

Do not run Terraform from the repo root. The repo root has no `.tf` files by design.

Run from a root module directory:

```bash
cd envs/nonprod
terraform init -backend=false
terraform validate
terraform plan -var-file=../../config/nonprod/account-c.tfvars
```

For a real local plan, authenticate with Azure first by installing `az` and running `az login`, or by setting `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, and `ARM_SUBSCRIPTION_ID`.
