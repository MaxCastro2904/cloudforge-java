#!/usr/bin/env bash
# Run once in AWS CloudShell with permission to manage IAM, only in a sandbox.
set -euo pipefail
export REPOSITORY="${1:?Usage: bash scripts/setup-oidc.sh OWNER/REPOSITORY [REGION] [PROJECT]}"
export AWS_REGION="${2:-us-east-1}"
export PROJECT_NAME="${3:-banbif-demo}"
[[ "$REPOSITORY" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]
[[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]{2,17}$ ]]
export ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
provider="arn:aws:iam::$ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$provider" >/dev/null 2>&1; then
  aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com >/dev/null
fi
folder=$(mktemp -d)
trap 'rm -rf "$folder"' EXIT
python3 - "$folder" <<'PYTHON'
import json,os,sys
from pathlib import Path
p=Path(sys.argv[1]); a=os.environ['ACCOUNT'];r=os.environ['AWS_REGION'];n=os.environ['PROJECT_NAME'];repo=os.environ['REPOSITORY']
trust={'Version':'2012-10-17','Statement':[{'Effect':'Allow','Principal':{'Federated':f'arn:aws:iam::{a}:oidc-provider/token.actions.githubusercontent.com'},'Action':'sts:AssumeRoleWithWebIdentity','Condition':{'StringEquals':{'token.actions.githubusercontent.com:aud':'sts.amazonaws.com','token.actions.githubusercontent.com:sub':f'repo:{repo}:environment:production'}}}]}
bucket=f'{n}-tfstate-{a}-{r}'
policy={'Version':'2012-10-17','Statement':[
 {'Effect':'Allow','Action':['s3:CreateBucket','s3:ListBucket','s3:GetBucketLocation','s3:GetBucketVersioning','s3:PutBucketVersioning','s3:GetEncryptionConfiguration','s3:PutEncryptionConfiguration','s3:GetBucketPublicAccessBlock','s3:PutBucketPublicAccessBlock','s3:GetBucketPolicy','s3:PutBucketPolicy'],'Resource':f'arn:aws:s3:::{bucket}'},
 {'Effect':'Allow','Action':['s3:GetObject','s3:PutObject','s3:DeleteObject'],'Resource':f'arn:aws:s3:::{bucket}/*'},
 {'Effect':'Allow','Action':['ecr:GetAuthorizationToken'],'Resource':'*'},
 {'Effect':'Allow','Action':['ecr:*'],'Resource':f'arn:aws:ecr:{r}:{a}:repository/{n}'},
 {'Effect':'Allow','Action':['ecs:*','elasticloadbalancing:*','ec2:Describe*','ec2:CreateVpc','ec2:DeleteVpc','ec2:ModifyVpcAttribute','ec2:CreateSubnet','ec2:DeleteSubnet','ec2:CreateInternetGateway','ec2:DeleteInternetGateway','ec2:AttachInternetGateway','ec2:DetachInternetGateway','ec2:CreateRouteTable','ec2:DeleteRouteTable','ec2:CreateRoute','ec2:DeleteRoute','ec2:AssociateRouteTable','ec2:DisassociateRouteTable','ec2:ReplaceRouteTableAssociation','ec2:CreateSecurityGroup','ec2:DeleteSecurityGroup','ec2:AuthorizeSecurityGroupIngress','ec2:RevokeSecurityGroupIngress','ec2:AuthorizeSecurityGroupEgress','ec2:RevokeSecurityGroupEgress','ec2:ModifySecurityGroupRules','ec2:CreateTags','ec2:DeleteTags','logs:DescribeLogGroups'],'Resource':'*','Condition':{'StringEquals':{'aws:RequestedRegion':r}}},
 {'Effect':'Allow','Action':['logs:CreateLogGroup','logs:DeleteLogGroup','logs:PutRetentionPolicy','logs:DeleteRetentionPolicy','logs:ListTagsForResource','logs:TagResource','logs:UntagResource','logs:ListTagsLogGroup','logs:TagLogGroup'],'Resource':f'arn:aws:logs:{r}:{a}:log-group:/ecs/{n}:*'},
 {'Effect':'Allow','Action':['iam:CreateRole','iam:GetRole','iam:DeleteRole','iam:TagRole','iam:UntagRole','iam:ListRolePolicies','iam:ListAttachedRolePolicies','iam:GetRolePolicy','iam:PutRolePolicy','iam:DeleteRolePolicy'],'Resource':f'arn:aws:iam::{a}:role/{n}-execution'},
 {'Effect':'Allow','Action':'iam:PassRole','Resource':f'arn:aws:iam::{a}:role/{n}-execution','Condition':{'StringEquals':{'iam:PassedToService':'ecs-tasks.amazonaws.com'}}},
 {'Effect':'Allow','Action':'iam:CreateServiceLinkedRole','Resource':[f'arn:aws:iam::{a}:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS*',f'arn:aws:iam::{a}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing*'],'Condition':{'StringEquals':{'iam:AWSServiceName':['ecs.amazonaws.com','elasticloadbalancing.amazonaws.com']}}}
]}
(p/'trust.json').write_text(json.dumps(trust));(p/'policy.json').write_text(json.dumps(policy))
PYTHON
role="$PROJECT_NAME-github"
if aws iam get-role --role-name "$role" >/dev/null 2>&1; then
  aws iam update-assume-role-policy --role-name "$role" --policy-document "file://$folder/trust.json"
else
  aws iam create-role --role-name "$role" --assume-role-policy-document "file://$folder/trust.json" >/dev/null
fi
aws iam put-role-policy --role-name "$role" --policy-name "$PROJECT_NAME-sandbox-deploy" --policy-document "file://$folder/policy.json"
echo "Set GitHub repository variable AWS_ROLE_ARN=arn:aws:iam::$ACCOUNT:role/$role"
echo "Set AWS_REGION=$AWS_REGION and PROJECT_NAME=$PROJECT_NAME"
