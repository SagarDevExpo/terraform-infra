#!/usr/bin/env sh
set -eu

workspace_id="${1:-}"
message="${2:-Triggered by GitLab CI}"

if [ -z "$workspace_id" ]; then
  echo "ERROR: workspace ID is required."
  exit 1
fi

if [ -z "${TFE_HOSTNAME:-}" ]; then
  echo "ERROR: TFE_HOSTNAME is required, for example app.terraform.io or tfe.company.com."
  exit 1
fi

if [ -z "${TFE_TOKEN:-}" ]; then
  echo "ERROR: TFE_TOKEN is required."
  exit 1
fi

payload=$(jq -n \
  --arg workspace_id "$workspace_id" \
  --arg message "$message" \
  '{
    data: {
      attributes: {
        message: $message,
        "is-destroy": false
      },
      type: "runs",
      relationships: {
        workspace: {
          data: {
            type: "workspaces",
            id: $workspace_id
          }
        }
      }
    }
  }')

echo "Triggering Terraform Enterprise run for workspace ${workspace_id}..."

response=$(curl -sS \
  --request POST \
  --header "Authorization: Bearer ${TFE_TOKEN}" \
  --header "Content-Type: application/vnd.api+json" \
  --data "$payload" \
  "https://${TFE_HOSTNAME}/api/v2/runs")

run_id=$(echo "$response" | jq -r '.data.id // empty')
run_status=$(echo "$response" | jq -r '.data.attributes.status // empty')
run_url=$(echo "$response" | jq -r '.data.links.self // empty')

if [ -z "$run_id" ]; then
  echo "ERROR: Failed to trigger Terraform Enterprise run."
  echo "$response" | jq .
  exit 1
fi

echo "Triggered Terraform Enterprise run: ${run_id}"
echo "Initial status: ${run_status}"
echo "API URL: https://${TFE_HOSTNAME}${run_url}"
