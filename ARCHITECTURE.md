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
flowchart TB
  Root[terraform-infra repo] --> CI[.gitlab-ci.yml]
  Root --> Scripts[scripts<br/>TFE trigger and compliance]
  Root --> Policies[policies<br/>OPA guardrails]
  Root --> TFEConfig[terraform-enterprise-config]
  Root --> Envs[envs]
  Root --> Config[config]
  Root --> Modules[modules]

  Envs --> Nonprod[envs/nonprod<br/>account root module]
  Envs --> Prod[envs/prod<br/>account-region root module]
  Envs --> Governance[envs/governance<br/>DR governance root]

  Config --> NPConfig[config/nonprod<br/>account-a account-b account-c]
  Config --> ProdConfig[config/prod<br/>account-region tfvars]
  Config --> GovConfig[config/governance/prod<br/>DR pairings]

  Modules --> Foundation[Foundation<br/>landing-zone]
  Modules --> Network[Network<br/>vnet firewall peering nat bastion app-gateway-waf]
  Modules --> Core[Core Platform<br/>acr keyvault aks private-endpoints]
  Modules --> Ops[Operations<br/>defender budget diagnostics]
  Modules --> Workloads[Workload Layer<br/>workload-identity gitops-addons container-apps redis postgres]

  Nonprod --> Foundation
  Nonprod --> Network
  Nonprod --> Core
  Nonprod --> Ops
  Nonprod --> Workloads

  Prod --> Foundation
  Prod --> Network
  Prod --> Core
  Prod --> Ops
  Prod --> Workloads

  Governance --> GovConfig
```

## Azure Resource Layering

```mermaid
flowchart TD
  subgraph LZ[Landing Zone Module]
    MgmtRG[Management RG]
    ConnRG[Connectivity RG]
    LAW[Log Analytics]
    Hub[Hub VNet]
    FwSubnet[AzureFirewallSubnet]
    SharedSubnet[Shared Services Subnet]
    BastionSubnet[AzureBastionSubnet optional]
    DNS[Private DNS Zones]
    Policy[Azure Policy Assignments]
  end

  subgraph Network[Network Add-Ons]
    Spoke[Spoke VNet]
    Subnets[AKS Private Endpoint<br/>App Gateway Container Apps Subnets]
    Peer[Hub-Spoke Peering]
    Firewall[Azure Firewall]
    NAT[NAT Gateway]
    Bastion[Azure Bastion]
    AGW[Application Gateway WAF]
  end

  subgraph Core[Core Platform]
    ACR[Azure Container Registry]
    KV[Key Vault]
    AKS[Private AKS]
    PE[Private Endpoints]
  end

  subgraph Workload[Workload And Ops Layer]
    WI[AKS Workload Identity]
    Flux[Flux GitOps Add-Ons]
    ACA[Azure Container Apps]
    Redis[Azure Cache for Redis]
    Postgres[PostgreSQL Flexible Server]
    Defender[Defender for Cloud]
    Budget[Budget Alerts]
    Diag[Diagnostic Settings]
  end

  Hub --> Peer
  Spoke --> Peer
  Spoke --> Subnets
  FwSubnet --> Firewall
  BastionSubnet --> Bastion
  SharedSubnet --> DNS
  Subnets --> AKS
  Subnets --> PE
  Subnets --> AGW
  Subnets --> ACA
  ACR --> PE
  KV --> PE
  Redis --> PE
  Postgres --> PE
  AKS --> WI
  AKS --> Flux
  LAW --> Diag
  Policy --> Core
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
  landing_zone      = true
  vnet              = false
  acr               = false
  keyvault          = false
  aks               = false
  firewall          = false
  bastion           = false
  vnet_peering      = false
  nat_gateway       = false
  app_gateway_waf   = false
  private_endpoints = false
  defender          = false
  budget            = false
  diagnostics       = false
  workload_identity = false
  gitops_addons     = false
  container_apps    = false
  redis             = false
  postgres          = false
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
  PlatformReady -- Yes --> EnableNetwork[Enable vnet]
  EnableNetwork --> EnableCore[Enable acr and keyvault]
  EnableCore --> EnableAKS[Enable aks]
  EnableNetwork --> EnableNetAddons[Optional network add-ons<br/>firewall peering nat bastion waf]
  EnableAKS --> EnableAKSAddons[Optional AKS add-ons<br/>workload identity and gitops]
  EnableCore --> EnableServices[Optional services<br/>private endpoints redis postgres container apps]
```

Guardrails:

- `aks = true` requires `landing_zone`, `vnet`, `acr`, and `keyvault`.
- `vnet`, `acr`, and `keyvault` require `landing_zone`.
- `firewall`, `bastion`, `defender`, `budget`, and `diagnostics` require `landing_zone`.
- `vnet_peering`, `nat_gateway`, `app_gateway_waf`, `private_endpoints`, `container_apps`, `redis`, and `postgres` require `landing_zone` and `vnet`.
- `workload_identity` and `gitops_addons` require `aks`.
- Critical resources use `prevent_destroy` so disabling an already-created module does not casually destroy infrastructure.
- GitLab compliance checks verify the `enabled_modules` block before triggering TFE.

```mermaid
flowchart LR
  LZ[landing_zone] --> VNet[vnet]
  LZ --> FoundationAddons[firewall bastion defender budget diagnostics]
  VNet --> PlatformAddons[vnet_peering nat_gateway app_gateway_waf private_endpoints container_apps redis postgres]
  VNet --> ACR[acr]
  VNet --> KV[keyvault]
  ACR --> AKS[aks]
  KV --> AKS
  AKS --> AKSAddons[workload_identity gitops_addons]
```

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

## GitLab To TFE Routing

```mermaid
flowchart TD
  Merge[Merge to main] --> Changed{Changed paths}

  Changed -->|config/nonprod/account-a.tfvars<br/>or nonprod shared path| NPA[nonprod account-a workspace]
  Changed -->|config/nonprod/account-b.tfvars<br/>or nonprod shared path| NPB[nonprod account-b workspace]
  Changed -->|config/nonprod/account-c.tfvars<br/>or nonprod shared path| NPC[nonprod account-c workspace]

  Changed -->|config/prod/account-c-eastus.tfvars| PCE[prod account-c eastus workspace]
  Changed -->|config/prod/account-c-eastus2.tfvars| PCE2[prod account-c eastus2 workspace]
  Changed -->|config/prod/account-d-centralus.tfvars| PDC[prod account-d centralus workspace]
  Changed -->|config/prod/account-d-westus2.tfvars| PDW[prod account-d westus2 workspace]

  Changed -->|envs/prod or modules shared change| ProdFleet[all affected prod regional workspaces]
  Changed -->|envs/governance or DR config| Gov[governance workspace]

  NPA --> AutoApply[non-prod auto apply]
  NPB --> AutoApply
  NPC --> AutoApply
  PCE --> Manual[prod manual approval]
  PCE2 --> Manual
  PDC --> Manual
  PDW --> Manual
  ProdFleet --> Manual
  Gov --> GovApply[governance approval as configured]
```

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
