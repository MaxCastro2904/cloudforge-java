#!/usr/bin/env bash
set -euo pipefail
: "${AWS_REGION:?Set AWS_REGION}"
: "${PROJECT_NAME:?Set PROJECT_NAME}"
account=$(aws sts get-caller-identity --query Account --output text)
bucket="${PROJECT_NAME}-tfstate-${account}-${AWS_REGION}"
if ! aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$bucket" --region "$AWS_REGION" >/dev/null
  else
    aws s3api create-bucket --bucket "$bucket" --region "$AWS_REGION" --create-bucket-configuration "LocationConstraint=$AWS_REGION" >/dev/null
  fi
fi
aws s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$bucket" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket "$bucket" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-policy --bucket "$bucket" --policy "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"DenyInsecureTransport\",\"Effect\":\"Deny\",\"Principal\":\"*\",\"Action\":\"s3:*\",\"Resource\":[\"arn:aws:s3:::$bucket\",\"arn:aws:s3:::$bucket/*\"],\"Condition\":{\"Bool\":{\"aws:SecureTransport\":\"false\"}}}]}"
echo "STATE_BUCKET=$bucket" >> "$GITHUB_ENV"
