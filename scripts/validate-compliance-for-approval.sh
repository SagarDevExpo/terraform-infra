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

if grep -R "hashicorp/aws\\|backend \"s3\"\\|aws_" "$env_dir" modules >/dev/null 2>&1; then
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
