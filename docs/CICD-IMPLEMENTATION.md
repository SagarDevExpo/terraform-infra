# CI/CD Implementation Guide — Terraform IaC Pipeline

This guide documents the end-to-end setup required to go from a fresh Azure account
and empty GitLab repo to a fully working IaC pipeline:

```
git push  →  GitLab (validate + compliance)  →  Terraform Cloud (plan + apply)  →  Azure
```

---

## Prerequisites

| Tool | Install | Verify |
|---|---|---|
| Terraform CLI | `brew install hashicorp/tap/terraform` | `terraform -version` |
| Azure CLI | `brew install azure-cli` | `az version` |
| Git | pre-installed on Mac | `git --version` |

---

## Part 1 — Azure Account

### 1.1 Log in and find your IDs

```bash
az login
az account show --query '{subscriptionId:id, tenantId:tenantId, name:name}' -o table
```

Note these — they go in your account `.tfvars` file:

| Value | Where to use |
|---|---|
| `subscriptionId` | `subscription_id` in tfvars |
| `tenantId` | `tenant_id` in tfvars |

### 1.2 Create a Service Principal (machine identity for CI/CD)

The SP is a non-human Azure identity that Terraform Cloud uses to authenticate.
It is NOT a human login — it's a "robot account" with controlled permissions.

```bash
az ad sp create-for-rbac \
  --name "sp-terraform-personal" \
  --role="Contributor" \
  --scopes="/subscriptions/<YOUR_SUBSCRIPTION_ID>" \
  --output json
```

Output:
```json
{
  "appId":       "...",   ← ARM_CLIENT_ID
  "password":    "...",   ← ARM_CLIENT_SECRET  (shown once — save it securely)
  "tenant":      "..."    ← ARM_TENANT_ID
}
```

> **Save the password immediately** — Azure will never show it again.
> Store credentials in a password manager, NOT in a plain text file.

### 1.3 Grant the SP additional permissions

**Contributor** allows the SP to create/update/delete resources but NOT:
- Create role assignments (`Microsoft.Authorization/roleAssignments/write`)
- Write Azure Policy definitions (`Microsoft.Authorization/policyDefinitions/write`)

Grant these additional roles so Terraform can manage RBAC and policies:

```bash
# Required to create role assignments (e.g. AcrPull, Key Vault Secrets User)
az role assignment create \
  --role "User Access Administrator" \
  --assignee "<SP_APP_ID>" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-<PREFIX>-platform"

# Required to create/update Azure Policy definitions at subscription level
az role assignment create \
  --role "Resource Policy Contributor" \
  --assignee "<SP_APP_ID>" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>"
```

> Scope `User Access Administrator` to the platform resource group, not the
> whole subscription — principle of least privilege.

### 1.4 Grant yourself Key Vault data plane access (via Terraform)

When Key Vault has `enable_rbac_authorization = true`, even the creator has no
data plane access by default. Grant it through Terraform (not ad-hoc CLI):

Add to `config/<env>/<account>.tfvars`:
```hcl
keyvault_admin_object_ids = ["<YOUR_ENTRA_ID_OBJECT_ID>"]
```

Get your object ID:
```bash
az ad signed-in-user show --query id -o tsv
```

In the portal: Entra ID → Users → click your name → Object ID field.

---

## Part 2 — Terraform Cloud

### 2.1 Create an organization

Go to `app.terraform.io` → Create organization (e.g. `cloudcentersdlc`).

### 2.2 Create a workspace

- New Workspace → **Version Control Workflow**
- Name: `terraform-infra-nonprod-account-personal`
  (convention: `terraform-infra-<env>-<account>`)

### 2.3 Connect workspace to GitLab VCS

Settings → Version Control → Edit:

| Setting | Value |
|---|---|
| VCS provider | GitLab.com |
| Repository | `cloudcentersdlc/terraform-infra` |
| Terraform Working Directory | `envs/nonprod` |
| VCS Branch | your working branch (e.g. `PI-00001`) |
| Automatic run triggering | **"Only trigger runs when files in specified paths change"** → enter `.tfc-never-auto-trigger` |

The fake path `.tfc-never-auto-trigger` disables auto-triggering on push —
GitLab CI controls when runs fire, not VCS webhooks.

### 2.4 Add workspace variables

Go to workspace → Variables tab. Add these as **Environment Variables**:

| Key | Value | Sensitive |
|---|---|---|
| `ARM_CLIENT_ID` | SP `appId` | No |
| `ARM_CLIENT_SECRET` | SP `password` | **Yes** |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID | No |
| `ARM_TENANT_ID` | Azure tenant ID | No |
| `TF_CLI_ARGS_plan` | `-var-file=../../config/nonprod/account-personal.tfvars` | No |
| `TF_CLI_ARGS_apply` | `-var-file=../../config/nonprod/account-personal.tfvars` | No |

The `TF_CLI_ARGS_*` variables automatically append `-var-file` to every plan/apply
so Terraform reads the account-specific values from the repo without hardcoding them.

### 2.5 Create a Terraform Cloud API token

User Settings (top-right avatar) → Tokens → Create API token → name it `gitlab-ci`.

**Copy the token — shown once only.** This goes into GitLab as `TFE_TOKEN`.

### 2.6 Get the workspace ID

Workspace → Settings → General → `Workspace ID: ws-xxxxxxxxxx`

This goes into GitLab as `TFE_WORKSPACE_ID_NONPROD_ACCOUNT_PERSONAL`.

---

## Part 3 — Local Terraform → Terraform Cloud (state migration)

When you've been running Terraform locally, state lives in
`envs/nonprod/terraform.tfstate`. Before GitLab can trigger TFC runs,
migrate this state to TFC so it knows about already-created resources.

### 3.1 Add the cloud backend to providers.tf

```hcl
# envs/nonprod/providers.tf
terraform {
  cloud {
    organization = "cloudcentersdlc"
    workspaces {
      name = "terraform-infra-nonprod-account-personal"
    }
  }
  ...
}
```

### 3.2 Authenticate and migrate

```bash
# Authenticate local Terraform CLI to TFC
terraform login app.terraform.io

# Re-initialize — Terraform detects local state and asks to upload it to TFC
cd envs/nonprod
terraform init
# Type "yes" when prompted to migrate state
```

Verify in TFC: workspace → States tab → should show existing resources.

---

## Part 4 — GitLab CI/CD Variables

Go to: `gitlab.com/<group>/<repo>` → Settings → CI/CD → Variables → Expand

Add these variables. **None should be "Protected"** if you're triggering from a
non-protected branch like a feature branch.

| Key | Value | Masked |
|---|---|---|
| `TFE_HOSTNAME` | `app.terraform.io` | No |
| `TFE_TOKEN` | TFC API token from Step 2.5 | **Yes** |
| `TFE_WORKSPACE_ID_NONPROD_ACCOUNT_PERSONAL` | workspace ID from Step 2.6 | No |

> **Protected variables** only inject into protected branches. If your working
> branch is not protected, variables marked Protected are invisible to the pipeline
> — it will error with "workspace ID is required."

---

## Part 5 — Pipeline Architecture

### How the pipeline works

```
Developer edits a .tf or .tfvars file
        │
        ▼
git push <branch>
        │
        ▼
GitLab reads .gitlab-ci.yml → starts pipeline
        │
   ┌────▼────┐
   │validate │  terraform fmt -check -recursive
   │         │  terraform init -backend=false
   └────┬────┘  terraform validate
        │
   ┌────▼────────┐
   │ compliance  │  scripts/validate-compliance-for-approval.sh
   │             │  checks security policy before ANY apply
   └────┬────────┘
        │
   ┌────▼────────┐  only runs if:
   │ trigger_tfe │  1. correct branch (e.g. "PI-00001")
   │             │  2. relevant files changed
   └────┬────────┘  calls: scripts/trigger-tfe-run.sh $WORKSPACE_ID
        │
        ▼
Terraform Cloud
  pulls code from GitLab (the connected VCS branch)
  reads workspace environment variables (ARM_*, TF_CLI_ARGS_*)
  runs: terraform plan -var-file=../../config/nonprod/account-personal.tfvars
  non-prod: auto-applies
  prod:     pauses for manual approval
        │
        ▼
Azure ARM API
  creates/updates/deletes resources
```

### Branch → account mapping

| Branch | Account | Auto-trigger TFC? |
|---|---|---|
| `PI-00001` | `account-personal` | Yes (on that branch) |
| `main` | `account-a`, `account-b`, `account-c`, prod | Yes (on main) |
| Any branch | All accounts — compliance only | No trigger |

### Three GitLab stages

| Stage | What runs | Fails on |
|---|---|---|
| `validate` | `terraform fmt -check`, `terraform validate` | Formatting errors, invalid HCL, type mismatches |
| `compliance` | `scripts/validate-compliance-for-approval.sh` | Security policy violations (e.g. missing tags enforcement, private cluster not enforced) |
| `trigger_tfe` | `scripts/trigger-tfe-run.sh` | TFC API errors, wrong workspace ID, bad token |

---

## Part 6 — Adding a New Account

To onboard a new Azure account to the same pipeline:

1. **Create a new `.tfvars` file:**
   ```
   config/nonprod/account-<name>.tfvars
   ```

2. **Add a workspace in TFC** and wire its variables (Steps 2.2–2.4).

3. **Add three blocks to `.gitlab-ci.yml`:**
   ```yaml
   # Change rule
   .nonprod_account_<name>_changes:
     rules:
       - changes: [envs/nonprod/**/*, config/nonprod/account-<name>.tfvars, modules/**/*]

   # Compliance job
   compliance_nonprod_account_<name>:
     extends: [.terraform_env, .nonprod_account_<name>_changes]
     stage: compliance
     script:
       - ./scripts/validate-compliance-for-approval.sh nonprod envs/nonprod config/nonprod/account-<name>.tfvars
     needs: [validate_nonprod]

   # Trigger job
   trigger_tfe_nonprod_account_<name>:
     extends: .trigger_tfe_env
     stage: trigger_tfe
     script:
       - ./scripts/trigger-tfe-run.sh "$TFE_WORKSPACE_ID_NONPROD_ACCOUNT_NAME" "..."
     needs: [compliance_nonprod_account_<name>]
     rules:
       - if: '$CI_COMMIT_BRANCH == "main"'
         changes: [modules/**/*, config/nonprod/account-<name>.tfvars]
   ```

4. **Add the GitLab CI variable:** `TFE_WORKSPACE_ID_NONPROD_ACCOUNT_NAME` = TFC workspace ID.

---

## Part 7 — Key Concepts Summary

### Why the SP needs multiple roles

| Role | Scope | Purpose |
|---|---|---|
| `Contributor` | Subscription | Create/update/delete Azure resources |
| `User Access Administrator` | Platform RG only | Create role assignments (AcrPull, KV Secrets User, etc.) |
| `Resource Policy Contributor` | Subscription | Create/update Azure Policy definitions |

### Why TFC uses VCS connection + `TF_CLI_ARGS`

TFC VCS-connected workspaces check out code from GitLab directly. They run
`terraform plan` from the working directory (`envs/nonprod`). The `TF_CLI_ARGS_plan`
environment variable injects `-var-file` automatically so each workspace targets the
right account without code changes.

### Why some resources are blocked by your own policies

The `require_tags` policy runs at subscription level with `enforce = true`. Azure
also auto-creates resources internally (Container Insights solutions, AKS node pool
VMSS, load balancers) that it doesn't tag. The policy must explicitly exclude:

```json
"not": { "field": "type", "in": ["Microsoft.OperationsManagement/solutions", ...] }
"not": { "value": "[resourceGroup().name]", "like": "MC_*" }
```

### Why `prevent_destroy = true` blocks terraform destroy

Guards on critical resources (clusters, workspaces, resource groups) mean Terraform
refuses to destroy them even with `terraform destroy`. This is intentional for prod.
For deliberate teardown of a learning account, delete resource groups directly via
Azure CLI:
```bash
az group delete --name <rg-name> --yes --no-wait
```

---

## Part 8 — Common Errors and Fixes

| Error | Root cause | Fix |
|---|---|---|
| `UnusedPolicyParameters` | Policy declares a parameter not used in its rule | Remove the unused `parameters {}` block |
| `AvailabilityZoneNotSupported` | B-series VMs don't support AZs | Set `availability_zones = []` in env root |
| `K8sVersionNotSupported` | Kubernetes version retired in the region | Update to a supported version (check `az aks get-versions`) |
| `VM size not allowed` | Free trial restricts older VM families | Switch to a v7-series VM (e.g. `Standard_D2s_v7`) |
| `ContainerInsights disallowed by policy` | Tag policy too broad; catches Azure-managed resources | Exclude `Microsoft.OperationsManagement/solutions` from policy rule |
| `VMSS disallowed by policy` | AKS node RG auto-creates untagged resources | Exclude `MC_*` resource groups from policy rule |
| `403 on policyDefinitions/write` | SP missing `Resource Policy Contributor` role | Grant `Resource Policy Contributor` at subscription level |
| `403 on roleAssignments/write` | SP missing `User Access Administrator` role | Grant `User Access Administrator` at platform RG level |
| `Resource already exists — needs import` | Partial creation orphaned resource in Azure | Delete from Azure and let Terraform recreate |
| `Workspace ID is required` | GitLab variable marked Protected, not available on branch | Uncheck Protected on the CI/CD variable |
| `terraform has no command named sh` | Docker image uses terraform as ENTRYPOINT | Add `entrypoint: [""]` to the image config in `.gitlab-ci.yml` |
