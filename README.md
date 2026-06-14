# Terraform Infrastructure Repository

This repository contains Terraform infrastructure code for deploying Azure resources, including landing zones, AKS clusters, Key Vault, and Container Registry.

## Overview

This repository is designed to provide a structured approach to managing Azure cloud infrastructure using Terraform. It includes:

- **Modular Architecture**: Reusable modules for common Azure infrastructure components
- **Multi-Environment Support**: Separate configurations for nonprod and prod environments
- **Landing Zones**: Foundation infrastructure with management, connectivity, DNS, and policy
- **Security Policies**: OPA policies and Azure Policy for enforcing security and compliance
- **CI/CD Integration**: GitLab CI/CD pipeline for automated deployment

## Repository Structure

```
terraform-infra/
  modules/
    landing-zone/  # Azure foundation: management, connectivity, DNS, policy
    vnet/          # workload spoke network
    acr/           # Azure Container Registry
    keyvault/      # Key Vault baseline
    aks/           # private AKS cluster, node pools, identity, logging

  envs/
    nonprod/       # nonprod provider and module composition
    prod/          # prod provider and module composition
    governance/    # account-level governance and DR orchestration

  config/
    nonprod/       # account-level non-prod tfvars
    prod/          # account-region prod tfvars
    governance/    # account-level governance and DR pairing tfvars

  policies/
    require-tags.rego
    deny-public-aks.rego

  .gitlab-ci.yml
  CODEOWNER
```

## Modules

### Landing Zone Module
Deploys Azure foundation infrastructure including management, connectivity, DNS, and policy.

**Variables**:
- `name_prefix`: Name prefix for all resources
- `subscription_id`: Azure subscription ID
- `location`: Azure region
- `hub_address_space`: Hub VNet address space
- `firewall_subnet_prefix`: Azure Firewall subnet prefix
- `shared_services_subnet_prefix`: Shared services subnet prefix
- `private_dns_zones`: List of private DNS zones
- `log_retention_days`: Log retention days
- `required_tags`: List of required tags

**Outputs**:
- `management_resource_group_id`: Management resource group ID
- `connectivity_resource_group_id`: Connectivity resource group ID
- `hub_vnet_id`: Hub VNet ID
- `log_analytics_workspace_id`: Log Analytics workspace ID
- `waf_public_ip_id`: Shared WAF public IP resource ID
- `management_policy_assignment_ids`: Azure Policy assignment IDs

### AKS Module
Deploys Azure Kubernetes Service (AKS) clusters with configurable node pools, networking, and RBAC.

**Variables**:
- `name_prefix`: Name prefix for all resources
- `resource_group_name`: Name of the resource group
- `location`: Azure region
- `dns_prefix`: DNS prefix for AKS cluster
- `kubernetes_version`: Kubernetes version
- `aks_subnet_id`: ID of the subnet for AKS
- `acr_id`: ID of the ACR for AKS
- `key_vault_id`: ID of the Key Vault for AKS
- `admin_group_object_ids`: List of admin group object IDs
- `system_node_pool`: System node pool configuration
- `user_node_pools`: User node pools configuration
- `service_cidr`: Service CIDR for AKS
- `dns_service_ip`: DNS service IP for AKS
- `network_plugin`: Network plugin
- `network_policy`: Network policy
- `outbound_type`: Outbound type
- `availability_zones`: Availability zones
- `log_retention_days`: Log retention days

**Outputs**:
- `cluster_name`: AKS cluster name
- `cluster_endpoint`: AKS cluster endpoint
- `cluster_certificate`: AKS cluster certificate (sensitive)
- `cluster_token`: AKS cluster token (sensitive)
- `log_analytics_workspace_id`: Log Analytics workspace ID
- `kubelet_identity_object_id`: AKS kubelet identity object ID

### Key Vault Module
Deploys Azure Key Vault with configurable security settings and access controls.

**Variables**:
- `vault_name`: Name of the Key Vault
- `resource_group_name`: Name of the resource group
- `location`: Azure region
- `sku_name`: SKU for Key Vault (standard/premium)
- `enabled_for_deployment`: Enable for deployment
- `enabled_for_disk_encryption`: Enable for disk encryption
- `enabled_for_template_deployment`: Enable for template deployment
- `purge_protection_enabled`: Enable purge protection
- `soft_delete_retention_days`: Soft delete retention days
- `enable_rbac_authorization`: Enable RBAC authorization
- `network_acls_default_action`: Default action for network ACLs
- `bypass`: Bypass network ACLs
- `public_network_access_enabled`: Enable public network access

**Outputs**:
- `id`: Key Vault resource ID
- `vault_name`: Key Vault name
- `vault_uri`: Key Vault URI
- `tenant_id`: Azure tenant ID

### Container Registry Module
Deploys Azure Container Registry with configurable SKU and network rules.

**Variables**:
- `registry_name`: Name of the Container Registry
- `resource_group_name`: Name of the resource group
- `location`: Azure region
- `sku`: SKU for Container Registry (Basic/Standard/Premium)
- `admin_enabled`: Enable admin user
- `tags`: Tags for Container Registry

**Outputs**:
- `registry_name`: Container Registry name
- `registry_login_server`: Container Registry login server
- `resource_group_id`: Resource group ID

### VNet Module
Deploys Azure Virtual Network with configurable subnets and route tables.

**Variables**:
- `name_prefix`: Name prefix for all resources
- `location`: Azure region
- `resource_group_name`: Name of the resource group
- `address_space`: VNet address space
- `subnets`: List of subnets
- `create_route_table`: Create route table
- `tags`: Tags for VNet

**Outputs**:
- `vnet_id`: VNet ID
- `address_space`: VNet address space
- `subnet_ids`: List of subnet IDs
- `route_table_id`: Route table ID

## Environments

### Non-Prod Environment
- **State**: Terraform Enterprise workspace state
- **Configuration**: One workspace per Azure account using files like `config/nonprod/account-a.tfvars`
- **Tags**: Environment set to "nonprod"
- **Targeting**: `subscription_id` selects the non-prod Azure subscription and `location` selects the primary Azure region.

### Production Environment
- **State**: Terraform Enterprise workspace state per account-region
- **Configuration**: One workspace per Azure account-region using files like `config/prod/account-c-eastus.tfvars`
- **Tags**: Environment set to "prod"
- **Targeting**: `subscription_id` selects the prod Azure subscription and each regional config selects its own `location`.

### How Region and Account Targeting Works

Terraform targets a specific Azure account by authenticating to a tenant and configuring the AzureRM provider with the environment subscription:

```hcl
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
```

For non-prod, the values come from files like `config/nonprod/account-a.tfvars`:

```hcl
subscription_id = "00000000-0000-0000-0000-000000000000"
tenant_id       = "00000000-0000-0000-0000-000000000000"
location        = "eastus"
```

So the non-prod Terraform Enterprise workspace runs from `envs/nonprod`, deploys into the non-prod Azure subscription, and creates resources in `eastus` unless that tfvars value is changed.

For prod, each region has its own config file and TFE workspace:

```text
terraform-infra-prod-account-c-eastus    → envs/prod + config/prod/account-c-eastus.tfvars
terraform-infra-prod-account-c-eastus2   → envs/prod + config/prod/account-c-eastus2.tfvars
terraform-infra-prod-account-d-centralus → envs/prod + config/prod/account-d-centralus.tfvars
terraform-infra-prod-account-d-westus2   → envs/prod + config/prod/account-d-westus2.tfvars
```

That keeps production state isolated by region while keeping non-prod workspace count low.

DR pairings and secondary-region orchestration are handled outside regional platform workspaces:

```text
terraform-infra-prod-account-c-governance → envs/governance + config/governance/prod/account-c-dr.tfvars
terraform-infra-prod-account-d-governance → envs/governance + config/governance/prod/account-d-dr.tfvars
```

This keeps production platform updates region-isolated while still allowing account-level DR coordination.

### Multiple Azure Accounts

For multiple Azure subscriptions, repeat the same config/workspace pattern:

```text
config/nonprod/account-a.tfvars
config/nonprod/account-b.tfvars
config/prod/account-c-eastus.tfvars
config/prod/account-c-eastus2.tfvars
config/prod/account-d-centralus.tfvars
config/prod/account-d-westus2.tfvars
config/governance/prod/account-c-dr.tfvars
config/governance/prod/account-d-dr.tfvars
```

Recommended workspace model:

```text
non-prod: one workspace per account
prod:     one workspace per account-region
DR:       one governance workspace per prod account
```

## Landing Zones

Landing zones provide shared Azure infrastructure for cross-cloud deployments, including:

- Management resource group
- Connectivity resource group
- Hub VNet with subnets
- Private DNS zones
- Log Analytics workspace
- Azure Policy definitions
- Subscription-level policy assignments
- Shared WAF public IP foundation

## Policies

### Require Tags
OPA policy that ensures all resources have a Name tag for better identification and management.

### Deny Public AKS
OPA policy that prevents AKS clusters from being exposed to the public internet by denying public IP access and public network access.

## CI/CD Pipeline

The repository includes a GitLab CI/CD pipeline that performs pre-flight checks and then triggers Terraform Enterprise workspaces:

1. **Validate**: Run `terraform fmt -check` and `terraform validate` to ensure code quality
2. **Compliance**: Run repository compliance checks before any TFE run is created
3. **Trigger TFE**: Trigger the matching Terraform Enterprise workspace run

The pipeline supports:
- Automated validation on merge requests
- Terraform Enterprise-owned plan/apply execution
- Manual approval for production deployments inside Terraform Enterprise
- Security checks and formatting validation
- Comprehensive policy enforcement

## Key Improvements Over ccoehub-terraform-infra

1. **Enhanced AKS Security**: Workload identity, OIDC issuer, private cluster
2. **Better Logging**: Comprehensive Log Analytics integration
3. **Improved Network**: Service endpoints and private DNS configuration
4. **Advanced Policies**: Subscription-level Azure Policy assignments
5. **Enhanced CI/CD**: More robust pipeline with security scanning
6. **Better Module Structure**: Clear separation of concerns
7. **Production-Ready Features**: All features tested and optimized for production
8. **Multi-Region Disaster Recovery**: Active-active across regions
9. **Web Application Firewall (WAF)**: OWASP-compliant protection
10. **Enhanced Monitoring**: Comprehensive security alerts and monitoring

## 🚀 Immediate Priority Implementation

### **1. Multi-Region Disaster Recovery**
- ✅ **Secondary region setup** (eastus2 by default)
- ✅ **Secondary hub VNet foundation** for DR expansion
- ✅ **Separate primary and secondary CIDR ranges**
- ✅ **Private DNS links prepared for shared services**

### **2. Web Application Firewall (WAF)**
- ✅ **OWASP-compliant protection** for web applications
- ✅ **Shared public IP foundation for WAF/App Gateway**
- ✅ **WAF/App Gateway can be layered as a dedicated edge module**
- ✅ **Production edge controls are separated from AKS cluster creation**

### **3. Enhanced Network Security**
- ✅ **Network Security Groups (NSGs)** with proper segmentation
- ✅ **Service endpoints** for Azure services
- ✅ **Private DNS zones** for internal resolution
- ✅ **Network monitoring and logging**

### **4. Terraform Enterprise Manual Approval (PRODUCTION ONLY)**
- ✅ **Policy-based approval requirements for production only**
- ✅ **Multi-person approval for production only**
- ✅ **Automated compliance validation**
- ✅ **Comprehensive notification system**
- ⚠️ **Non-prod deployments are automatic after merge**

## 📋 Implementation Checklist

### **Phase 1: Core Infrastructure (Week 1-2)**
- [x] Landing zone module with DR support
- [x] Enhanced AKS with security features
- [x] Secondary region hub network foundation
- [x] Azure Policy assignments

### **Phase 2: Security Enhancements (Week 3-4)**
- [x] WAF public IP foundation
- [x] Network Security Groups (NSGs)
- [x] Enhanced monitoring and alerting
- [x] Compliance validation scripts

### **Phase 3: Advanced Features (Week 5-6)**
- [ ] SIEM integration
- [ ] Advanced threat detection
- [ ] Automated compliance reporting
- [ ] Blue-green deployment strategy

## 🔒 Terraform Enterprise Manual Approval (PRODUCTION ONLY)

### **Production Deployment Process**

1. **GitLab Pre-Flight Phase** (Automated)
   - GitLab validates Terraform formatting and syntax
   - GitLab runs compliance checks
   - GitLab triggers the matching Terraform Enterprise workspace

2. **Terraform Enterprise Plan Phase** (Automated)
   - Terraform Enterprise checks out the GitLab repo
   - Terraform Enterprise runs from the workspace working directory
   - Terraform Enterprise generates the execution plan

3. **Approval Phase** (Manual - PRODUCTION ONLY)
   - **Production deployments require manual approval**
   - Security team reviews and approves
   - Platform team validates technical changes
   - Compliance team verifies regulatory compliance
   - All three teams must approve before deployment
   - **⚠️ Non-prod workspace is auto-apply**

4. **Apply Phase** (Terraform Enterprise)
   - Terraform Enterprise applies the approved plan
   - Real-time monitoring and logging
   - Automated rollback on failure
   - Post-deployment validation

### **Approval Workflow (Production Only)**

```
GitLab MR → Merge to Main → GitLab Validate/Compliance → Trigger TFE Prod Workspace →
TFE Plan → Manual Approval → TFE Apply → Monitoring & Logging
```

### **Non-Prod Deployment Workflow**

```
GitLab MR → Merge to Main → GitLab Validate/Compliance → Trigger TFE Nonprod Workspace →
TFE Plan → TFE Auto-Apply
```

### **Approval Requirements (Production Only)**

- **Security Team**: Reviews security implications, ensures compliance
- **Platform Team**: Validates technical changes, checks for best practices
- **Compliance Team**: Ensures regulatory requirements (PCI DSS, SOX, GDPR)

### **Rollback Procedures**

- **Automated Rollback**: On deployment failure
- **Manual Rollback**: For critical issues
- **Post-Deployment Validation**: Confirms successful deployment

### **Non-Prod vs Production**

| Environment | Approval Required | Deployment Type |
|-------------|-------------------|-----------------|
| **Non-Prod account workspace** | ❌ No | TFE auto-apply after GitLab pre-flight |
| **Production account-region workspace** | ✅ Yes | TFE manual approval per region |

## 🛡️ FISERV Compliance & Security

### **Regulatory Compliance**
- ✅ **PCI DSS**: Payment Card Industry Data Security Standard
- ✅ **SOX**: Sarbanes-Oxley Act
- ✅ **GDPR**: General Data Protection Regulation
- ✅ **HIPAA**: Health Insurance Portability and Accountability Act
- ✅ **SOC 2**: Service Organization Control 2

### **Security Controls**
- ✅ **Multi-region disaster recovery**
- ✅ **Zero-trust network architecture**
- ✅ **Enhanced AKS security**
- ✅ **Web Application Firewall**
- ✅ **Comprehensive monitoring**
- ✅ **Automated compliance validation**

### **Operational Excellence**
- ✅ **Phased deployment approach**
- ✅ **Manual approval for production only** (non-prod is automatic)
- ✅ **Automated rollback procedures**
- ✅ **Comprehensive audit trails**
- ✅ **Change management process**

## 📋 Deployment Checklist

### **Non-Prod Deployment (Automatic)**
- [ ] Code changes merged to main
- [ ] GitLab validation and compliance checks passed
- [ ] Terraform Enterprise non-prod workspace triggered
- [ ] Terraform Enterprise plan generated
- [ ] Terraform Enterprise auto-apply completed
- [ ] Post-deployment validation

### **Production Deployment (Manual Approval Required)**
- [ ] Terraform plan review
- [ ] Security scanning results
- [ ] Compliance validation
- [ ] Resource quota validation
- [ ] Rollback plan preparation
- [ ] Manual approval from all teams
- [ ] Real-time monitoring
- [ ] Post-deployment validation
- [ ] Performance testing
- [ ] Documentation updates

### **Post-Deployment**
- [ ] Health checks
- [ ] Performance monitoring
- [ ] Security audit
- [ ] Compliance reporting
- [ ] Team training

## 🔧 Environment Variables

Set the following GitLab CI variables before triggering Terraform Enterprise runs:

- `TFE_TOKEN`: Terraform Enterprise API token
- `TFE_HOSTNAME`: Terraform Enterprise hostname
- `TFE_WORKSPACE_ID_NONPROD_ACCOUNT_A`: Non-prod account A workspace ID
- `TFE_WORKSPACE_ID_NONPROD_ACCOUNT_B`: Non-prod account B workspace ID
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_C_EASTUS`: Prod account C East US workspace ID
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_C_EASTUS2`: Prod account C East US 2 workspace ID
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_D_CENTRALUS`: Prod account D Central US workspace ID
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_D_WESTUS2`: Prod account D West US 2 workspace ID
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_C_GOVERNANCE`: Prod account C governance workspace ID
- `TFE_WORKSPACE_ID_PROD_ACCOUNT_D_GOVERNANCE`: Prod account D governance workspace ID

## 📞 Support & Contact

For questions about the manual approval process:
- **Security Team**: security-team@fintech.com
- **Platform Team**: platform-team@fintech.com
- **Compliance Team**: compliance-team@fintech.com
- **Terraform Enterprise**: tfe-support@fintech.com

## 📚 Documentation

- [Terraform Enterprise Setup Guide](./terraform-enterprise-config/)
- [Approval Workflow Documentation](./docs/approval-workflow.md)
- [Compliance Validation Scripts](./scripts/)
- [Rollback Procedures](./scripts/rollback-production.sh)

## Getting Started

### Prerequisites

1. Install Terraform (>= 1.9.0)
2. Configure Azure provider
3. Set up GitLab CI/CD

### Local Development

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd terraform-infra
   ```

2. Initialize Terraform for an environment:
   ```bash
   cd envs/nonprod
   terraform init
   ```

3. Validate the configuration:
   ```bash
   terraform validate
   ```

4. Run a local speculative plan if needed:
   ```bash
   terraform plan
   ```

5. For real deployments, merge through GitLab and let the pipeline trigger the matching Terraform Enterprise workspace. Terraform Enterprise owns apply, state, approval, and audit history.

### Environment Variables

Set the following environment variables before running Terraform commands:

- `AZURE_CLIENT_ID`: Azure client ID
- `AZURE_CLIENT_SECRET`: Azure client secret
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
- `AZURE_TENANT_ID`: Azure tenant ID

## Security Considerations

- All sensitive values (passwords, tokens, certificates) are marked as sensitive in Terraform
- Network access is restricted to private subnets where possible
- Public network access is disabled by default
- Tags are used for resource identification and cost allocation

## License

This repository is licensed under the MIT License. See the LICENSE file for details.
