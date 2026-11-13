#!/usr/bin/env bash
# Run from CloudShell using an administrator session, before the deployment workflow.
set -euo pipefail
export TF_VAR_repository="${1:?Usage: bootstrap-infra.sh OWNER/REPO [REGION] [PROJECT]}"
export TF_VAR_aws_region="${2:-us-east-2}"
export TF_VAR_project_name="${3:-banbif-demo}"
export AWS_REGION="$TF_VAR_aws_region"
[[ "$TF_VAR_repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]
[[ "$TF_VAR_project_name" =~ ^[a-z][a-z0-9-]{2,17}$ ]]
project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
stack="$project_root/infra/bootstrap"
if ! command -v terraform >/dev/null; then
  install_dir="$HOME/.local/bin"
  mkdir -p "$install_dir"
  temporary=$(mktemp -d)
  trap 'rm -rf "$temporary"' EXIT
  terraform_version=1.13.5
  archive="terraform_${terraform_version}_linux_amd64.zip"
  base="https://releases.hashicorp.com/terraform/$terraform_version"
  curl --fail --silent --show-error --location "$base/$archive" -o "$temporary/$archive"
  curl --fail --silent --show-error --location "$base/terraform_${terraform_version}_SHA256SUMS" -o "$temporary/SHA256SUMS"
  (cd "$temporary" && rg_line=$(awk -v name="$archive" '$2 == name {print}' SHA256SUMS) && test -n "$rg_line" && printf '%s\n' "$rg_line" | sha256sum -c -)
  unzip -o "$temporary/$archive" terraform -d "$install_dir" >/dev/null
  export PATH="$install_dir:$PATH"
fi
identity=$(python3 - <<'PY'
import os,json,urllib.request
repo=os.environ['TF_VAR_repository']
request=urllib.request.Request('https://api.github.com/repos/'+repo,headers={'User-Agent':'CloudForge-bootstrap'})
with urllib.request.urlopen(request,timeout=30) as response:
    data=json.load(response)
print(str(data['owner']['id'])+' '+str(data['id']))
PY
)
read -r TF_VAR_repository_owner_id TF_VAR_repository_id <<< "$identity"
export TF_VAR_repository_owner_id TF_VAR_repository_id
account=$(aws sts get-caller-identity --query Account --output text)
bucket="$TF_VAR_project_name-tfstate-$account-$AWS_REGION"
role="$TF_VAR_project_name-github"
provider="arn:aws:iam::$account:oidc-provider/token.actions.githubusercontent.com"
existing_bucket=false
if aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
  existing_bucket=true
  printf 'terraform {\n  backend "s3" {}\n}\n' > "$stack/backend.tf"
  terraform -chdir="$stack" init -reconfigure -input=false \
    -backend-config="bucket=$bucket" -backend-config="key=bootstrap/terraform.tfstate" \
    -backend-config="region=$AWS_REGION" -backend-config="encrypt=true" -backend-config="use_lockfile=true"
else
  if [[ -f "$stack/backend.tf" ]]; then
    echo 'Configured remote state bucket is unavailable. Check account, region and access.' >&2
    exit 1
  fi
  terraform -chdir="$stack" init -input=false
fi
terraform -chdir="$stack" validate -no-color
terraform -chdir="$stack" state list > "$stack/current-resources.txt" 2>/dev/null || :
trap 'rm -f "$stack/current-resources.txt"' EXIT
adopt() {
  local address="$1" identifier="$2"
  if ! grep -Fxq "$address" "$stack/current-resources.txt"; then
    terraform -chdir="$stack" import -input=false -lock-timeout=5m "$address" "$identifier"
  fi
}
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$provider" >/dev/null 2>&1; then
  adopt aws_iam_openid_connect_provider.github "$provider"
fi
if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
  adopt aws_iam_role.github "$role"
  for entry in "deploy:$TF_VAR_project_name-sandbox-deploy" "compatibility:$TF_VAR_project_name-permissions-fix" "cloudfront:cloudforge-cloudfront"; do
    address="${entry%%:*}"; policy_name="${entry#*:}"
    if aws iam get-role-policy --role-name "$role" --policy-name "$policy_name" >/dev/null 2>&1; then
      adopt "aws_iam_role_policy.$address" "$role:$policy_name"
    fi
  done
fi
if [[ "$existing_bucket" == true ]]; then
  adopt aws_s3_bucket.state "$bucket"
  adopt aws_s3_bucket_versioning.state "$bucket"
  adopt aws_s3_bucket_server_side_encryption_configuration.state "$bucket"
  adopt aws_s3_bucket_public_access_block.state "$bucket"
  adopt aws_s3_bucket_policy.state "$bucket"
fi
terraform -chdir="$stack" plan -lock-timeout=5m -out=bootstrap.tfplan
terraform -chdir="$stack" apply -lock-timeout=5m bootstrap.tfplan
if [[ "$existing_bucket" == false ]]; then
  printf 'terraform {\n  backend "s3" {}\n}\n' > "$stack/backend.tf"
  terraform -chdir="$stack" init -migrate-state -force-copy -input=false \
    -backend-config="bucket=$bucket" -backend-config="key=bootstrap/terraform.tfstate" \
    -backend-config="region=$AWS_REGION" -backend-config="encrypt=true" -backend-config="use_lockfile=true"
fi
echo "AWS_ROLE_ARN=$(terraform -chdir="$stack" output -raw github_role_arn)"
echo "AWS_REGION=$AWS_REGION"
echo "PROJECT_NAME=$TF_VAR_project_name"
echo 'Bootstrap completed. Existing application resources were not modified.'
