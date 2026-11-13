terraform {
  required_version = ">= 1.10.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project_name" {
  type    = string
  default = "banbif-demo"
}

variable "repository" {
  type = string
}

variable "repository_owner_id" {
  type = string
}

variable "repository_id" {
  type = string
}

data "aws_caller_identity" "current" {}

locals {
  account = data.aws_caller_identity.current.account_id
  bucket  = "${var.project_name}-tfstate-${local.account}-${var.aws_region}"
  owner   = split("/", var.repository)[0]
  repo    = split("/", var.repository)[1]
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github" {
  name                 = "${var.project_name}-github"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.repository}:environment:production",
            "repo:${local.owner}@${var.repository_owner_id}/${local.repo}@${var.repository_id}:environment:production"
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "deploy" {
  name = "${var.project_name}-sandbox-deploy"
  role = aws_iam_role.github.id
  policy = templatefile("${path.module}/deploy-policy.json.tftpl", {
    account = local.account
    region  = var.aws_region
    project = var.project_name
  })
}

resource "aws_iam_role_policy" "compatibility" {
  name = "${var.project_name}-permissions-fix"
  role = aws_iam_role.github.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "ec2:GetSecurityGroupsForVpc"
        Resource  = "*"
        Condition = { StringEquals = { "aws:RequestedRegion" = var.aws_region } }
      },
      {
        Effect   = "Allow"
        Action   = ["logs:ListTagsForResource", "logs:TagResource", "logs:UntagResource"]
        Resource = "arn:aws:logs:${var.aws_region}:${local.account}:log-group:/ecs/${var.project_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudfront" {
  name = "cloudforge-cloudfront"
  role = aws_iam_role.github.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution", "cloudfront:GetDistributionConfig",
          "cloudfront:UpdateDistribution", "cloudfront:DeleteDistribution",
          "cloudfront:ListTagsForResource", "cloudfront:TagResource", "cloudfront:UntagResource"
        ]
        Resource  = "arn:aws:cloudfront::${local.account}:distribution/*"
        Condition = { StringEquals = { "aws:ResourceTag/Project" = var.project_name } }
      },
      {
        Effect    = "Allow"
        Action    = ["cloudfront:CreateDistribution", "cloudfront:CreateDistributionWithTags"]
        Resource  = "*"
        Condition = { StringEquals = { "aws:RequestTag/Project" = var.project_name } }
      },
      {
        Effect    = "Allow"
        Action    = "cloudfront:TagResource"
        Resource  = "arn:aws:cloudfront::${local.account}:distribution/*"
        Condition = { StringEquals = { "aws:RequestTag/Project" = var.project_name } }
      }
    ]
  })
}

resource "aws_s3_bucket" "state" {
  bucket        = local.bucket
  force_destroy = false
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

output "github_role_arn" {
  value = aws_iam_role.github.arn
}

output "state_bucket" {
  value = aws_s3_bucket.state.id
}
