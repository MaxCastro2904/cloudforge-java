#!/usr/bin/env bash
set -euo pipefail
stack="${1:?Usage: terraform-init.sh registry|service}"
[[ "$stack" == "registry" || "$stack" == "service" ]]
: "${STATE_BUCKET:?Set STATE_BUCKET}"
: "${AWS_REGION:?Set AWS_REGION}"
terraform -chdir="infra/$stack" init -input=false \
  -backend-config="bucket=$STATE_BUCKET" \
  -backend-config="key=$stack/terraform.tfstate" \
  -backend-config="region=$AWS_REGION" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"
