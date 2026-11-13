#!/usr/bin/env bash
# The backend is provisioned by infra/bootstrap; workflows only check access.
set -euo pipefail
: "${AWS_REGION:?Set AWS_REGION}"
: "${PROJECT_NAME:?Set PROJECT_NAME}"
: "${GITHUB_ENV:?Run this script from GitHub Actions}"
account=$(aws sts get-caller-identity --query Account --output text)
bucket="${PROJECT_NAME}-tfstate-${account}-${AWS_REGION}"
aws s3api head-bucket --bucket "$bucket"
versioning=$(aws s3api get-bucket-versioning --bucket "$bucket" --query Status --output text)
if [[ "$versioning" != "Enabled" ]]; then
  echo 'State bucket versioning is not enabled. Run the Terraform bootstrap first.' >&2
  exit 1
fi
echo "STATE_BUCKET=$bucket" >> "$GITHUB_ENV"
