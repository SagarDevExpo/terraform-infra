#!/usr/bin/env sh
set -eu

environment="${1:-}"
env_dir="${2:-}"
var_file="${3:-}"

if [ -z "$environment" ] || [ -z "$env_dir" ] || [ -z "$var_file" ]; then
  echo "Usage: $0 <nonprod|prod> <env-dir> <var-file>"
  exit 1
fi

if [ ! -d "$env_dir" ]; then
  echo "ERROR: Environment directory not found: $env_dir"
  exit 1
fi

if [ ! -f "$var_file" ]; then
  echo "ERROR: Variable file not found: $var_file"
  exit 1
fi

failures=0

check_passed() {
  echo "✅ $1"
}

check_failed() {
  echo "❌ $1"
  failures=$((failures + 1))
}

contains() {
  grep -R "$1" "$2" >/dev/null 2>&1
}

echo "🔍 Running ${environment} compliance checks before triggering Terraform Enterprise..."

if contains 'source  = "hashicorp/azurerm"' "$env_dir"; then
  check_passed "AzureRM provider is configured."
else
  check_failed "AzureRM provider is missing from ${env_dir}."
fi

if grep -R 'backend "' "$env_dir" >/dev/null 2>&1; then
  check_failed "External backend block found in ${env_dir}; TFE should own state for this workflow."
else
  check_passed "No external backend configured; Terraform Enterprise owns state."
fi

if contains "subscription_id = var.subscription_id" "$env_dir"; then
  check_passed "Workspace targets Azure subscription through variables."
else
  check_failed "Provider does not use subscription_id variable."
fi

if contains "location" "$var_file"; then
  check_passed "Primary Azure region is explicitly set in ${var_file}."
else
  check_failed "Primary Azure region is not set in ${var_file}."
fi

if find "$env_dir" modules -name "*.tf" -print | xargs grep -E "hashicorp/aws|backend \"s3\"|resource \"aws_|data \"aws_" >/dev/null 2>&1; then
  check_failed "AWS provider/backend leftovers found in Azure Terraform path."
else
  check_passed "No AWS provider/backend leftovers found."
fi

if contains "private_cluster_enabled           = true" "modules/aks"; then
  check_passed "AKS private cluster is enforced."
else
  check_failed "AKS private cluster is not enforced."
fi

if contains "local_account_disabled            = true" "modules/aks"; then
  check_passed "AKS local admin account is disabled."
else
  check_failed "AKS local admin account is not disabled."
fi

if contains "workload_identity_enabled         = true" "modules/aks"; then
  check_passed "AKS workload identity is enabled."
else
  check_failed "AKS workload identity is not enabled."
fi

if contains "public_network_access_enabled = false" "$env_dir/main.tf"; then
  check_passed "Key Vault public network access is disabled by environment composition."
else
  check_failed "Key Vault public network access is not disabled in ${env_dir}/main.tf."
fi

if contains "name_prefix" "$var_file"; then
  check_passed "Config provides a unique resource name prefix."
else
  check_failed "Config file does not provide name_prefix."
fi

if contains "enabled_modules" "$var_file"; then
  check_passed "Config declares enabled_modules for phased onboarding."
else
  check_failed "Config file does not declare enabled_modules."
fi

if awk '
  /enabled_modules[[:space:]]*=/ { in_block=1 }
  in_block && /aks[[:space:]]*=[[:space:]]*true/ { aks=1 }
  in_block && /vnet[[:space:]]*=[[:space:]]*true/ { vnet=1 }
  in_block && /acr[[:space:]]*=[[:space:]]*true/ { acr=1 }
  in_block && /keyvault[[:space:]]*=[[:space:]]*true/ { keyvault=1 }
  in_block && /landing_zone[[:space:]]*=[[:space:]]*true/ { landing=1 }
  in_block && /^}/ { in_block=0 }
  END { exit !(aks && !(landing && vnet && acr && keyvault)) }
' "$var_file"; then
  check_failed "enabled_modules.aks=true requires landing_zone, vnet, acr, and keyvault to also be true."
else
  check_passed "enabled_modules dependency check passed."
fi

if awk '
  /enabled_modules[[:space:]]*=/ { in_block=1 }
  in_block && /(firewall|bastion|defender|budget|diagnostics)[[:space:]]*=[[:space:]]*true/ { foundation=1 }
  in_block && /landing_zone[[:space:]]*=[[:space:]]*true/ { landing=1 }
  in_block && /^}/ { in_block=0 }
  END { exit !(foundation && !landing) }
' "$var_file"; then
  check_failed "Foundation add-ons require landing_zone=true."
else
  check_passed "Foundation add-on dependency check passed."
fi

if awk '
  /enabled_modules[[:space:]]*=/ { in_block=1 }
  in_block && /(vnet_peering|nat_gateway|app_gateway_waf|private_endpoints|container_apps|redis|postgres)[[:space:]]*=[[:space:]]*true/ { platform=1 }
  in_block && /landing_zone[[:space:]]*=[[:space:]]*true/ { landing=1 }
  in_block && /vnet[[:space:]]*=[[:space:]]*true/ { vnet=1 }
  in_block && /^}/ { in_block=0 }
  END { exit !(platform && !(landing && vnet)) }
' "$var_file"; then
  check_failed "Platform add-ons require landing_zone=true and vnet=true."
else
  check_passed "Platform add-on dependency check passed."
fi

if awk '
  /enabled_modules[[:space:]]*=/ { in_block=1 }
  in_block && /(workload_identity|gitops_addons)[[:space:]]*=[[:space:]]*true/ { aks_addon=1 }
  in_block && /aks[[:space:]]*=[[:space:]]*true/ { aks=1 }
  in_block && /^}/ { in_block=0 }
  END { exit !(aks_addon && !aks) }
' "$var_file"; then
  check_failed "AKS add-ons require aks=true."
else
  check_passed "AKS add-on dependency check passed."
fi

if contains "CostCenter" "$var_file" && contains "DataClass" "$var_file"; then
  check_passed "Required governance tags are present in config."
else
  check_failed "Required governance tags CostCenter/DataClass are missing."
fi

if [ "$environment" = "prod" ]; then
  if contains 'sku                     = "Premium"' "$env_dir/main.tf"; then
    check_passed "Prod ACR uses Premium SKU."
  else
    check_failed "Prod ACR should use Premium SKU."
  fi

  if contains "zone_redundancy_enabled = true" "$env_dir/main.tf"; then
    check_passed "Prod ACR zone redundancy is enabled."
  else
    check_failed "Prod ACR zone redundancy is not enabled."
  fi
fi

if [ "$failures" -gt 0 ]; then
  echo "❌ Compliance failed with ${failures} issue(s). Terraform Enterprise run will not be triggered."
  exit 1
fi

echo "✅ Compliance passed. Terraform Enterprise run can be triggered."
